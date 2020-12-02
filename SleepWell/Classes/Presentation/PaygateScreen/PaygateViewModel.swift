//
//  PaygateViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

enum PaygateCompletionResult {
    case purchased, restored, closed
}

protocol PaygateViewModelInterface {
    var purchaseProcessing: RxActivityIndicator { get }
    var restoreProcessing: RxActivityIndicator { get }
    var retrieveCompleted: BehaviorRelay<Bool> { get }
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom! { get set }
    
    func retrieve() -> Driver<(Paygate?, Bool)>
    
    var buySubscription: PublishRelay<String> { get }
    var restoreSubscription: PublishRelay<String> { get }
    
    func buied() -> Signal<Bool>
    func restored() -> Signal<Bool>
    
    func dismiss()
}

final class PaygateViewModel: BindableViewModel, PaygateViewModelInterface {
    enum PaygateOpenedFrom: String {
        case onboarding = "onboarding"
        case meditations = "meditations"
        case stories = "stories"
        case scenes = "scenes"
        case sounds = "sounds"
        case promotionInApp = "promotionInApp"
    }
    
    typealias Interface = PaygateViewModelInterface
    
    lazy var router: PaygateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let paygateManager: PaygateManager
        let purchaseService: PurchaseService
        let personalDataService: PersonalDataService
    }
    
    let purchaseProcessing = RxActivityIndicator()
    let restoreProcessing = RxActivityIndicator()
    let retrieveCompleted = BehaviorRelay<Bool>(value: false)
    
    let buySubscription = PublishRelay<String>()
    let restoreSubscription = PublishRelay<String>()
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom!
    
    private let purchaseInteractor = SDKStorage.shared.purchaseInteractor
    
    func dismiss() {
        router.dismiss()
    }
}

// MARK: Get paygate content

extension PaygateViewModel {
    func retrieve() -> Driver<(Paygate?, Bool)> {
        let paygate = dependencies
            .paygateManager
            .retrievePaygate(screen: openedFrom.rawValue)
            .asDriver(onErrorJustReturn: nil)
        
        let prices = paygate
            .flatMapLatest { [weak self] response -> Driver<PaygateMapper.PaygateResponse?> in
                guard let `self` = self, let response = response else {
                    return .deferred { .just(nil) }
                }
                
                return self.dependencies
                    .paygateManager
                    .prepareProductsPrices(for: response)
                    .asDriver(onErrorJustReturn: nil)
            }
        
        return Driver
            .merge([paygate.map { ($0?.paygate, false) },
                    prices.map { ($0?.paygate, true) }])
                .do(onNext: { [weak self] stub in
                    self?.retrieveCompleted.accept(stub.1)
                })
    }
}

// MARK: Make purchase

extension PaygateViewModel {
    func buied() -> Signal<Bool> {
        buySubscription
            .flatMapLatest { [weak self] productId -> Observable<Bool> in
                guard let this = self else {
                    return .empty()
                }
                
                return this.purchaseInteractor
                    .makeActiveSubscriptionByBuy(productId: productId)
                    .asObservable()
                    .flatMap { result -> Single<Bool> in
                        switch result {
                        case .cancelled:
                            return .just(false)
                        case .completed(let response):
                            guard response != nil else {
                                return .just(false)
                            }
                            
                            switch this.openedFrom! {
                            case .onboarding, .promotionInApp:
                                   return .just(true)
                            case .meditations, .stories, .scenes, .sounds:
                                return this.dependencies.personalDataService
                                        .sendPersonalData()
                                        .map { true }
                                        .catchErrorJustReturn(true)
                            }
                        }
                    }
                    .catchErrorJustReturn(false)
                    .trackActivity(this.purchaseProcessing)
            }
            .asSignal(onErrorJustReturn: false)
    }
    
    func restored() -> Signal<Bool> {
        restoreSubscription
            .flatMapLatest { [weak self] productId -> Observable<Bool> in
                guard let this = self else {
                    return .empty()
                }
                
                return this.purchaseInteractor
                    .makeActiveSubscriptionByRestore()
                    .asObservable()
                    .flatMap { result -> Single<Bool> in
                        switch result {
                        case .cancelled:
                            return .just(false)
                        case .completed(let response):
                            guard response != nil else {
                                return .just(false)
                            }
                            
                            switch this.openedFrom! {
                            case .onboarding, .promotionInApp:
                                   return .just(true)
                            case .meditations, .stories, .scenes, .sounds:
                                return this.dependencies.personalDataService
                                        .sendPersonalData()
                                        .map { true }
                                        .catchErrorJustReturn(true)
                            }
                        }
                    }
                    .catchErrorJustReturn(false)
                    .trackActivity(this.restoreProcessing)
            }
            .asSignal(onErrorJustReturn: false)
    }
}
