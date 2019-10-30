//
//  OnboardingRouter.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class OnboardingRouter: Routing {
    private let router: Router
    
    required init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func goToPaygate(completion: @escaping (PaygateCompletionResult) -> ()) {
        router.present(type: PaygateAssembly.self,
                       input: PaygateViewController.Input(openedFrom: .onboarding, completion: completion))
    }
    
    func goToMainScreen(behave: MainScreenBehave) {
        router.setRootVC(type: MainAssembly.self)
    }
}
