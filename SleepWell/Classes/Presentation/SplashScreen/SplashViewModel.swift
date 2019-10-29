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
        case main
        case onboarding(OnboardingViewModel.Behave)
    }
    
    lazy var step = createStep()
    
    private let sessionService = SessionService()
    private let purchaseService = PurchaseService()
    private let personalDataService = PersonalDataService()
    
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
                    return .just(.main)
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
                                return .main
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
            return .onboarding(.simple)
        } else {
            return .onboarding(.requirePersonalData)
        }
    }
}
