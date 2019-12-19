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
    var paygateLoading: RxActivityIndicator { get }
    var paymentLoading: RxActivityIndicator { get }
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom! { get set }
    
    func paygate() -> Driver<Paygate?>
    
    func buy() -> Driver<Bool>
    func restore() -> Driver<Bool>
    
    func dismiss()
}

final class PaygateViewModel: BindableViewModel, PaygateViewModelInterface {
    enum PaygateOpenedFrom {
        case onboarding
        case paidContent
        case promotionInApp
    }
    
    typealias Interface = PaygateViewModelInterface
    
    lazy var router: PaygateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let paygateService: PaygateService
        let purchaseService: PurchaseService
        let personalDataService: PersonalDataService
    }
    
    let paygateLoading = RxActivityIndicator()
    let paymentLoading = RxActivityIndicator()
    
    var openedFrom: PaygateViewModel.PaygateOpenedFrom!
    
    private let productId = BehaviorRelay<String?>(value: nil)
    
    func paygate() -> Driver<Paygate?> {
        return dependencies.paygateService
            .paygete()
            .do(onSuccess: { [weak self] paygate in
                self?.productId.accept(paygate?.productId)
            })
            .trackActivity(paygateLoading)
            .asDriver(onErrorJustReturn: nil)
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
            .flatMap { [dependencies, openedFrom] _ -> Single<Void> in
                return dependencies.purchaseService
                    .paymentValidate()
                    .flatMap { _ -> Single<Void> in
                        switch openedFrom! {
                        case .onboarding:
                            return .just(Void())
                        case .paidContent:
                            return dependencies.personalDataService
                                .sendPersonalData()
                                .catchErrorJustReturn(Void())
                        case .promotionInApp:
                            return .just(Void())
                        }
                    }
            }
        
        return purchase
            .trackActivity(paygateLoading)
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
                        case .paidContent:
                            return dependencies.personalDataService
                                .sendPersonalData()
                                .catchErrorJustReturn(Void())
                        case .promotionInApp:
                            return .just(Void())
                        }
                    }
            }
        
        return purchase
            .trackActivity(paygateLoading)
            .map { true }
            .asDriver(onErrorJustReturn: false)
    }
}
