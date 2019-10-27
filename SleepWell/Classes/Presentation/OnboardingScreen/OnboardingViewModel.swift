//
//  OnboardingViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol OnboardingViewModelInterface {
    
}

final class OnboardingViewModel: BindableViewModel {
    enum Behave {
        case simple
        case requirePersonalData
    }
    
    typealias Interface = OnboardingViewModelInterface
    
    lazy var router: OnboardingRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension OnboardingViewModel: OnboardingViewModelInterface {
    
}
