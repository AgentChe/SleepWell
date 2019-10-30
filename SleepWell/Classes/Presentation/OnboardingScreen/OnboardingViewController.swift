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
    @IBOutlet weak var startView: OnboardingStartView!
    @IBOutlet weak var aimsView: OnboardingAimsView!
    @IBOutlet weak var personalDataView: OnboardingPersonalDataView!
    
    private let disposeBag = DisposeBag()
}

extension OnboardingViewController: BindsToViewModel {
    typealias ViewModel = OnboardingViewModel
    
    struct Input {
        let behave: OnboardingViewModel.Behave
    }
    
    static func make() -> OnboardingViewController {
        let storyboard = UIStoryboard(name: "OnboardingScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "OnboardingViewController") as! OnboardingViewController
    }
    
    func bind(to viewModel: OnboardingViewModelInterface, with input: Input) -> () {
        startView.show()
        
        startView.start
            .subscribe(onNext: { [weak self] in
                viewModel.goToPaygate { _ in
                    self?.startView.hide {
                        self?.aimsView.show()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        aimsView.nextWithAims
            .subscribe(onNext: { [weak self] aims in
                self?.aimsView.hide {
                    self?.personalDataView.show()
                }
            })
            .disposed(by: disposeBag)
        
        personalDataView.nextWithPersonalData
            .subscribe(onNext: { [weak self] personalData in
                self?.personalDataView.hide {
                    
                }
            })
            .disposed(by: disposeBag)
    }
}
