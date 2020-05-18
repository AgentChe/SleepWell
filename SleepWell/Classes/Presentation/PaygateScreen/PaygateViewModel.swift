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
    var paygateLoading: Driver<Bool> { get }
    var paymentLoading: RxActivityIndicator { get }
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom! { get set }
    
    func paygate() -> Driver<Paygate?>
    
    func buy() -> Driver<Bool>
    func restore() -> Driver<Bool>
    
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
        let paygateService: PaygateService
        let purchaseService: PurchaseService
        let personalDataService: PersonalDataService
    }
    
    private(set) lazy var paygateLoading = _paygateLoading.asDriver(onErrorJustReturn: false)
    let _paygateLoading = PublishRelay<Bool>()
    
    let paymentLoading = RxActivityIndicator()
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom!
    
    private let productId = BehaviorRelay<String?>(value: nil)
    
    func paygate() -> Driver<Paygate?> {
        _paygateLoading.accept(true)
        
        let response = dependencies.paygateService
            .getPaygate(from: openedFrom.rawValue)
            .asDriver(onErrorJustReturn: nil)
            
        let price = response
            .flatMapLatest { [unowned self] response -> Driver<Paygate?> in
                guard let response = response else {
                    return .just(nil)
                }
                
                return self.dependencies.paygateService
                    .getProductPrice(response: response)
                    .asDriver(onErrorJustReturn: nil)
            }
            .do(onNext: { [weak self] _ in
                self?._paygateLoading.accept(false)
            })
        
        let info = response
            .map { PaygateMapper.create(info: $0?.info ?? [:], productPrice: nil) }
            .do(onNext: { [weak self] paygate in
                self?.productId.accept(paygate?.productId)
            })
        
        return Driver.concat([info, price])
    }
    
    func dismiss() {
        router.dismiss()
    }
    
    func buy() -> Driver<Bool> {
        guard let productId = self.productId.value else {
            return .just(false)
        }
        
        let purchase = dependencies.purchaseService
            .buySubscription(productId: productId)
            .do(onSuccess: { _ in FacebookAnalytics.shared.logPurchase(amount: 0, currency: "USD") })
            .flatMap { [dependencies, openedFrom] _ -> Single<Void> in
                return dependencies.purchaseService
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
        
        return purchase
            .trackActivity(paymentLoading)
            .map { true }
            .asDriver(onErrorJustReturn: false)
    }
    
    func restore() -> Driver<Bool> {
        guard let productId = self.productId.value else {
            return .just(false)
        }
        
        let purchase = dependencies.purchaseService
            .restoreSubscription(productId: productId)
            .flatMap { [dependencies, openedFrom] _ -> Single<Void> in
                return dependencies.purchaseService
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
        
        return purchase
            .trackActivity(paymentLoading)
            .map { true }
            .asDriver(onErrorJustReturn: false)
    }
}
