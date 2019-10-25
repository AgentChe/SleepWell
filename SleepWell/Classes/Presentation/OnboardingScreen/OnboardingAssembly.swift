//
//  OnboardingScreenAssembly.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class OnboardingAssembly: ScreenAssembly {
    typealias VC = OnboardingViewController
    
    func assembleDependencies() -> OnboardingViewModel.Dependencies {
        return VC.ViewModel.Dependencies()
    }
}
