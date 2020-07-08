//
//  PaygateViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class PaygateViewController: UIViewController {
    private enum Scene {
        case not, main, specialOffer
    }
    
    var paygateView = PaygateView()
    
    private let disposeBag = DisposeBag()
    
    private var currentScene = Scene.not
    
    private var viewModel: PaygateViewModelInterface?
    
    deinit {
        paygateView.specialOfferView.stopTimer()
    }
    
    override func loadView() {
        super.loadView()
        
        view = paygateView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PaygateViewController.isFirstOpening {
            PaygateViewController.isFirstOpening = false

            viewModel?.startPing.accept(Void())
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel?.stopPing.accept(Void())
    }
}

extension PaygateViewController: BindsToViewModel {
    typealias ViewModel = PaygateViewModel
    typealias Input = (openedFrom: PaygateViewModel.PaygateOpenedFrom, completion: ((PaygateCompletionResult) -> (Void))?)
    
    static func make() -> PaygateViewController {
        let vc = PaygateViewController(nibName: nil, bundle: nil)
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    func bind(to viewModel: PaygateViewModelInterface, with input: Input) -> () {
        var vm = viewModel
        vm.openedFrom = input.openedFrom
        self.viewModel = vm 
        
        paygateView.mainView.setup(design: input.openedFrom)
        paygateView.closeButton.isHidden = true
        
        addMainOptionsSelection(viewModel: viewModel)
        
        AppStateProxy.ApplicationProxy
            .willResignActive
            .bind(to: viewModel.stopPing)
            .disposed(by: disposeBag)
        
        let retrieved = viewModel.retrieve()
        
        retrieved
            .drive(onNext: { [weak self] paygate, completed in
                guard let `self` = self, let paygate = paygate else {
                    return
                }
                
                let flow = PaygateManager.shared.getFlow() ?? PaygateFlow.paygateUponRequest
                self.paygateView.closeButton.isHidden = flow == PaygateFlow.blockOnboarding && paygate.specialOffer == nil
                
                self.paygateView.mainView.setup(paygate: paygate.main)
                
                if let specialOffer = paygate.specialOffer {
                    self.paygateView.specialOfferView.setup(paygate: specialOffer)
                }
                
                if completed {
                    self.currentScene = .main
                }
                
                self.animateShowMainContent(isLoading: !completed)
            })
            .disposed(by: disposeBag)
        
        let paygate = retrieved
            .map { $0.0 }
            .startWith(nil)
        
        paygateView
            .closeButton.rx.tap
            .withLatestFrom(paygate)
            .subscribe(onNext: { [unowned self] paygate in
                switch self.currentScene {
                case .not:
                    input.completion?(.closed)
                    viewModel.dismiss()
                case .main:
                    if paygate?.specialOffer != nil {
                        let flow = PaygateManager.shared.getFlow() ?? PaygateFlow.paygateUponRequest
                        self.paygateView.closeButton.isHidden = flow == PaygateFlow.blockOnboarding
                            
                        self.animateMoveToSpecialOfferView()
                        self.currentScene = .specialOffer
                    } else {
                        input.completion?(.closed)
                        viewModel.dismiss()
                    }
                case .specialOffer:
                    self.paygateView.specialOfferView.stopTimer()
                    input.completion?(.closed)
                    viewModel.dismiss()
                }
            })
            .disposed(by: disposeBag)
        
        paygateView
            .mainView
            .continueButton.rx.tap
            .map { [unowned self] in
                [self.paygateView.mainView.leftOptionView, self.paygateView.mainView.rightOptionView]
                    .first(where: { $0.isSelected })?
                    .productId
            }
            .subscribe(onNext: { productId in
                guard let productId = productId else {
                    return
                }
                
                viewModel.buySubscription.accept(productId)
            })
            .disposed(by: disposeBag)
        
        paygateView
            .mainView
            .restoreButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                guard let productId = [self.paygateView.mainView.leftOptionView, self.paygateView.mainView.rightOptionView]
                    .first(where: { $0.isSelected })?
                    .productId
                else {
                    return
                }
                
                viewModel.restoreSubscription.accept(productId)
            })
            .disposed(by: disposeBag)
        
        paygateView
            .specialOfferView
            .continueButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let productId = self?.paygateView.specialOfferView.specialOffer?.productId else {
                    return
                }
                
                viewModel.buySubscription.accept(productId)
            })
            .disposed(by: disposeBag)
        
        paygateView
            .specialOfferView
            .restoreButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let productId = self?.paygateView.specialOfferView.specialOffer?.productId else {
                    return
                }
                
                viewModel.restoreSubscription.accept(productId)
            })
            .disposed(by: disposeBag)
        
        Driver
            .merge(viewModel.purchaseProcessing.asDriver(),
                   viewModel.restoreProcessing.asDriver(),
                   viewModel.retrieveCompleted.asDriver(onErrorJustReturn: true).map { !$0 })
            .drive(onNext: { [weak self] isLoading in
                self?.paygateView.mainView.continueButton.isHidden = isLoading
                self?.paygateView.mainView.restoreButton.isHidden = isLoading
                self?.paygateView.specialOfferView.continueButton.isHidden = isLoading
                self?.paygateView.specialOfferView.restoreButton.isHidden = isLoading

                isLoading ? self?.paygateView.mainView.purchasePreloaderView.startAnimating() : self?.paygateView.mainView.purchasePreloaderView.stopAnimating()
                isLoading ? self?.paygateView.specialOfferView.purchasePreloaderView.startAnimating() : self?.paygateView.specialOfferView.purchasePreloaderView.stopAnimating()
            })
            .disposed(by: disposeBag)
        
        viewModel
            .error
            .drive(onNext: { [weak self] error in
                self?.paygateView.errorBanner.show(with: error)
            })
            .disposed(by: disposeBag)
        
        paygateView
            .errorBanner
            .tapForHide
            .subscribe(onNext: { [weak self] in
                self?.paygateView.errorBanner.hide()
            })
            .disposed(by: disposeBag)
        
        Signal
            .merge(viewModel.purchaseCompleted.map { PaygateCompletionResult.purchased },
                   viewModel.restoredCompleted.map { PaygateCompletionResult.restored })
            .emit(onNext: { result in
                input.completion?(result)
                viewModel.dismiss()
            })
            .disposed(by: disposeBag)
        
        // MARK: Not emitted
        
        viewModel
            .ping()
            .drive()
            .disposed(by: disposeBag)
    }
}

// MARK: Private

private extension PaygateViewController {
    static var isFirstOpening: Bool {
        set {
            UserDefaults.standard.set(true, forKey: "paygate_was_opened")
        }
        
        get {
            !UserDefaults.standard.bool(forKey: "paygate_was_opened")
        }
    }
    
    func updateCloseButtonVisible(paygate: Paygate) {
        
    }
    
    func addMainOptionsSelection(viewModel: PaygateViewModelInterface) {
        let leftOptionTapGesture = UITapGestureRecognizer()
        paygateView.mainView.leftOptionView.addGestureRecognizer(leftOptionTapGesture)
        
        leftOptionTapGesture.rx.event
            .subscribe(onNext: { [unowned self] _ in
                if let productId = self.paygateView.mainView.leftOptionView.productId {
                    viewModel.buySubscription.accept(productId)
                }
                
                guard !self.paygateView.mainView.leftOptionView.isSelected else {
                    return
                }
                
                self.paygateView.mainView.leftOptionView.isSelected = true
                self.paygateView.mainView.rightOptionView.isSelected = false
            })
            .disposed(by: disposeBag)
        
        let rightOptionTapGesture = UITapGestureRecognizer()
        paygateView.mainView.rightOptionView.addGestureRecognizer(rightOptionTapGesture)
        
        rightOptionTapGesture.rx.event
            .subscribe(onNext: { [unowned self] _ in
                if let productId = self.paygateView.mainView.rightOptionView.productId {
                    viewModel.buySubscription.accept(productId)
                }
                
                guard !self.paygateView.mainView.rightOptionView.isSelected else {
                    return
                }
                
                self.paygateView.mainView.leftOptionView.isSelected = false
                self.paygateView.mainView.rightOptionView.isSelected = true
            })
            .disposed(by: disposeBag)
    }
    
    func animateShowMainContent(isLoading: Bool) {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            self?.paygateView.mainView.greetingLabel.alpha = 1
            self?.paygateView.mainView.iconView.alpha = 1
            self?.paygateView.mainView.textLabel.alpha = 1
            self?.paygateView.mainView.lockImageView.alpha = 1
            self?.paygateView.mainView.termsOfferLabel.alpha = 1
            self?.paygateView.mainView.leftOptionView.alpha = 1
            self?.paygateView.mainView.rightOptionView.alpha = 1
            self?.paygateView.mainView.restoreButton.alpha = 1
        })
    }
    
    func animateMoveToSpecialOfferView() {
        paygateView.specialOfferView.isHidden = false
        paygateView.specialOfferView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.paygateView.mainView.alpha = 0
            self?.paygateView.specialOfferView.alpha = 1
        }, completion: { [weak self] _ in
            self?.paygateView.specialOfferView.startTimer()
        })
    }
}
