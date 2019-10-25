//
//  OnboardingViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift

final class OnboardingViewController: UIViewController {
    
}

extension OnboardingViewController: BindsToViewModel {
    typealias ViewModel = OnboardingViewModel
    
    static func make() -> OnboardingViewController {
        let storyboard = UIStoryboard(name: "OnboardingScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
    }
    
    func bind(to viewModel: OnboardingViewModelInterface, with input: ()) -> () {
        
    }
}
