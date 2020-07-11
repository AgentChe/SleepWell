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
    
    var purchaseCompleted: Signal<Void> { get }
    var restoredCompleted: Signal<Void> { get }
    
    var error: Driver<String> { get }
    
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
    
    lazy var purchaseCompleted = buy()
    lazy var restoredCompleted = restore()
    
    lazy var error = _error.asDriver(onErrorDriveWith: .never())
    private var _error = PublishRelay<String>()
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom!
    
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

private extension PaygateViewModel {
    func buy() -> Signal<Void> {
        let purchase = buySubscription
            .flatMapLatest { [dependencies, openedFrom, purchaseProcessing] productId -> Observable<Void> in
                dependencies.purchaseService
                    .buySubscription(productId: productId)
                    .flatMap {
                        dependencies.purchaseService
                            .paymentValidate()
                            .flatMap { _ -> Single<Void> in
                             switch openedFrom! {
                             case .onboarding:
                                    return .just(Void())
                             case .meditations, .stories, .scenes, .sounds:
                                    return dependencies.personalDataService
                                        .sendPersonalData()
                                        .catchErrorJustReturn(Void())
                             case .promotionInApp:
                                    return .just(Void())
                                }
                            }
                }
                .trackActivity(purchaseProcessing)
                .do(onNext: { _ in
                    FacebookAnalytics.shared.logPurchase(amount: 0, currency: "USD")
                }, onError: { [weak self] _ in
                    self?._error.accept("Paygate.FailedPurchase".localized)
                })
                .catchError { _ in .never() }
            }
        
        return purchase
            .asSignal(onErrorSignalWith: .never())
    }
    
    func restore() -> Signal<Void> {
        let purchase = restoreSubscription
            .flatMapLatest { [dependencies, openedFrom, restoreProcessing] productId -> Observable<Void> in
                dependencies.purchaseService
                    .restoreSubscription(productId: productId)
                    .flatMap {
                        dependencies.purchaseService
                            .paymentValidate()
                            .flatMap { _ -> Single<Void> in
                                switch openedFrom! {
                                case .onboarding:
                                    return .just(Void())
                                case .meditations, .stories, .scenes, .sounds:
                                    return dependencies.personalDataService
                                        .sendPersonalData()
                                        .catchErrorJustReturn(Void())
                                case .promotionInApp:
                                    return .just(Void())
                                }
                            }
                    }
                    .trackActivity(restoreProcessing)
                    .do(onNext: { _ in
                        FacebookAnalytics.shared.logPurchase(amount: 0, currency: "USD")
                    }, onError: { [weak self] _ in
                        self?._error.accept("Paygate.FailedRestore".localized)
                    })
                    .catchError { _ in .never() }
            }
        
        return purchase
            .asSignal(onErrorSignalWith: .never())
    }
}
