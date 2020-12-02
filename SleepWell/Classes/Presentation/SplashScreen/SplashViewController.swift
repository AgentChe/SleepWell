//
//  SplashViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SplashViewController: UIViewController {
    var generateStepSignal: Signal<Void>!
    
    private lazy var router = Router(transitionHandler: self)
    private let viewModel = SplashViewModel()
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.step
            .subscribe(onNext: { [weak self] step in
                switch step {
                case .main(let behave):
                    self?.goToMainScreen(behave: behave)
                case .onboarding(let behave):
                    self?.goToOnboardingScreen(behave: behave)
                }
            })
            .disposed(by: disposeBag)
        
        generateStepSignal
            .emit(to: viewModel.makeStep)
            .disposed(by: disposeBag)
    }
    
    private func goToOnboardingScreen(behave: OnboardingViewModel.Behave) {
        router.setRootVC(type: OnboardingAssembly.self,
                         input: .init(behave: behave),
                         animationOptions: .transitionCrossDissolve,
                         duration: 0.3)
    }
    
    private func goToMainScreen(behave: MainScreenBehave) {
        router.setRootVC(type: MainAssembly.self,
                         input: .init(behave: behave),
                         animationOptions: .transitionCrossDissolve,
                         duration: 0.3)
    }
}
