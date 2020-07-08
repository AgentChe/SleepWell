//
//  SplashViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

class SplashViewModel {
    enum Step {
        case main(MainScreenBehave)
        case onboarding(OnboardingViewModel.Behave)
    }
    
    lazy var step = updateCacheAndCreateStep()
    
    private let sessionService = SessionService()
    private let purchaseService = PurchaseService()
    private let personalDataService = PersonalDataService()
    
    private let cacheService = CacheService()
    
    private func updateCacheAndCreateStep() -> Single<Step> {
        Single
            .zip(cacheService.update(),
                 PaygateManager.retrieveFlow().catchErrorJustReturn(nil))
            .flatMap { [weak self] _ in
                self?.createStep() ?? .never()
            }
    }
    
    private func createStep() -> Single<Step> {
        if let userToken = SessionService.userToken {
            return check(userToken: userToken)
        } else {
            return validate()
        }
    }
    
    private func check(userToken: String) -> Single<Step> {
        return sessionService.check(userToken: userToken)
            .catchErrorJustReturn(nil)
            .flatMap { [unowned self] session -> Single<Step> in
                if session?.userToken != nil {
                    return .just(.main(session?.activeSubscription == true ? .withActiveSubscription : .withoutActiveSubscription))
                } else {
                    return self.validate()
                }
            }
    }
    
    private func validate() -> Single<Step> {
        return purchaseService.receipt
            .flatMap { [unowned self] receipt -> Single<Step> in
                if let receipt = receipt {
                    return self.purchaseService
                        .paymentValidate(receipt: receipt)
                        .catchErrorJustReturn(nil)
                        .map { session -> Step in
                            if session?.userToken != nil {
                                return .main(session?.activeSubscription == true ? .withActiveSubscription : .withoutActiveSubscription)
                            } else {
                                return self.checkPersonalData()
                            }
                        }
                } else {
                    return .just(self.checkPersonalData())
                }
            }
    }
    
    private func checkPersonalData() -> Step {
        if self.personalDataService.hasPersonalData() {
            return .main(.withoutActiveSubscription)
        } else {
            return .onboarding(.requirePersonalData)
        }
    }
}
