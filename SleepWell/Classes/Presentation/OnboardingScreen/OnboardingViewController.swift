//
//  OnboardingViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class OnboardingViewController: UIViewController {
    @IBOutlet weak var startView: OnboardingStartView!
    @IBOutlet weak var aimsView: OnboardingAimsView!
    @IBOutlet weak var personalDataView: OnboardingPersonalDataView!
    @IBOutlet weak var bedtimeView: OnboardingBedtimeView!
    @IBOutlet weak var welcomeView: OnboardingWelcomeView!
    
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
        var paygateResult: PaygateCompletionResult?
        
        startView.show()
        
        startView.nextUp
            .subscribe(onNext: { [weak self] in
                viewModel.goToPaygate { result in
                    paygateResult = result
                    
                    self?.startView.hide {
                        switch input.behave {
                        case .simple:
                            self?.welcomeView.show()
                        case .requirePersonalData:
                            self?.aimsView.show()
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        aimsView.nextUpWithAims
            .subscribe(onNext: { [weak self] aims in
                viewModel.setAims.accept(aims)
                
                self?.aimsView.hide {
                    self?.personalDataView.show()
                }
            })
            .disposed(by: disposeBag)
        
        personalDataView.nextUpWithPersonalData
            .subscribe(onNext: { [weak self] personalData in
                viewModel.setGender.accept(personalData.0)
                viewModel.setBirthYear.accept(personalData.1)
                
                self?.personalDataView.hide {
                    self?.bedtimeView.show()
                }
            })
            .disposed(by: disposeBag)
        
        Observable
            .merge(
                bedtimeView.nextUpWithTimeAndPushToken.take(1)
                    .do(onNext: { stub in
                        viewModel.setPushToken.accept(stub.pushToken)
                        viewModel.setPushTime.accept(stub.time)
                    })
                    .map { _ -> Void in Void() },
                bedtimeView.nextUpWithout.take(1)
                    .do(onNext: {
                        viewModel.setPushToken.accept(nil)
                        viewModel.setPushTime.accept(nil)
                    })
                    .asObservable()
            )
            .subscribe(onNext: { [weak self] in
                self?.bedtimeView.hide {
                    self?.welcomeView.show()
                }
            })
            .disposed(by: disposeBag)
        
        welcomeView.nextUpWithSwipeDirection
            .subscribe(onNext: { [weak self] swipeDirection in
                self?.welcomeView.hide(swipeDirection: swipeDirection) {
                    viewModel.complete(with: paygateResult!, behave: input.behave)
                        .emit(onNext: { behave in
                            viewModel.goToMainScreen(behave: behave)
                        })
                        .disposed(by: self!.disposeBag)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.buildPersonalData()
            .emit()
            .disposed(by: disposeBag)
    }
}
