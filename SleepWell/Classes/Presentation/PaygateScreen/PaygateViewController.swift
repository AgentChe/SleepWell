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
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restorePurchaseButton: UIButton!
    @IBOutlet weak var preloaderView: UIActivityIndicatorView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var freeAccessLabel: UILabel!
    @IBOutlet weak var errorView: ErrorView!
    @IBOutlet weak var feature1Label: UILabel!
    @IBOutlet weak var feature2Label: UILabel!
    @IBOutlet weak var feature3Label: UILabel!
    
    @IBOutlet weak var logoImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var title1ContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var title2ContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var title3ContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var buyButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var restorePurchaseButtonTopConstraint: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    
    fileprivate var isBuyOrRestoreAtUserAction: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    private func configure() {
        logoImageViewTopConstraint.constant = SizeUtils.value(largeDevice: 110, smallDevice: 80, verySmallDevice: 50)
        title1ContainerViewTopConstraint.constant = SizeUtils.value(largeDevice: 58, smallDevice: 45, verySmallDevice: 30)
        title2ContainerViewTopConstraint.constant = SizeUtils.value(largeDevice: 32, smallDevice: 24, verySmallDevice: 16)
        title3ContainerViewTopConstraint.constant = SizeUtils.value(largeDevice: 32, smallDevice: 24, verySmallDevice: 16)
        buyButtonTopConstraint.constant = SizeUtils.value(largeDevice: 110, smallDevice: 90, verySmallDevice: 70)
        restorePurchaseButtonTopConstraint.constant = SizeUtils.value(largeDevice: 76, smallDevice: 50, verySmallDevice: 40)
    }
}

extension PaygateViewController: BindsToViewModel {
    typealias ViewModel = PaygateViewModel
    typealias Input = (openedFrom: PaygateViewModel.PaygateOpenedFrom, completion: ((PaygateCompletionResult) -> (Void))?)
    
    static func make() -> PaygateViewController {
        let storyboard = UIStoryboard(name: "PaygateScreen", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PaygateViewController") as! PaygateViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    func bind(to viewModel: PaygateViewModelInterface, with input: Input) -> () {
        var vm = viewModel
        vm.openedFrom = input.openedFrom
        
        viewModel.paygateLoading
            .drive(onNext: { [weak self] loading in
                loading ? self?.preloaderView.startAnimating() : self?.preloaderView.stopAnimating()
                self?.buyButton.isEnabled = !loading
                self?.restorePurchaseButton.isEnabled = !loading
                self?.priceLabel.isHidden = loading
                self?.freeAccessLabel.isHidden = loading
            })
            .disposed(by: disposeBag)
        
        viewModel.paymentLoading
            .drive(onNext: { [weak self] loading in
                self?.closeButton.isEnabled = !loading
                self?.buyButton.isEnabled = !loading
                self?.restorePurchaseButton.isEnabled = !loading
            })
            .disposed(by: disposeBag)
        
        viewModel.paygate()
            .drive(onNext: { [weak self] paygate in
                self?.buyButton.setTitle(paygate?.buyButtonText, for: .normal)
                self?.priceLabel.text = paygate?.postBuyButtonInfo
                self?.freeAccessLabel.text = paygate?.preBuyButtonInfo
                
                let features = paygate?.features ?? []
                [self?.feature1Label, self?.feature2Label, self?.feature3Label]
                    .prefix(features.count)
                    .enumerated()
                    .forEach { $1?.text = features[$0] }
            })
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: {
                input.completion?(.closed)
                viewModel.dismiss()
            })
            .disposed(by: disposeBag)
        
        
        let buySignal = buyButton.rx.tap.asDriver()
            .do(onNext: { [weak self] in self?.isBuyOrRestoreAtUserAction = true })
            .flatMapLatest { _ in viewModel.buy() }
            .map { ($0, PaygateCompletionResult.purchased) }
        
        let restoreTrigger = PublishRelay<Void>()
        let restoreSignal = Driver.merge(restorePurchaseButton.rx.tap.asDriver(), restoreTrigger.asDriver(onErrorDriveWith: .never()))
            .do(onNext: { [weak self] in self?.isBuyOrRestoreAtUserAction = true })
            .flatMapLatest { _ in viewModel.restore() }
            .map { ($0, PaygateCompletionResult.restored) }
        
        Driver<(Bool, PaygateCompletionResult)>
            .merge(buySignal, restoreSignal)
            .drive(onNext: { [weak self] stub in
                let (isSuccess, result) = stub
                
                if isSuccess {
                    RateManager.showRateController()
                    input.completion?(result)
                    viewModel.dismiss()
                } else {
                    self?.errorView.show(with: "Failed purchase")
                }
            })
            .disposed(by: disposeBag)
        
        if viewModel.openedFrom == .promotionInApp {
            isBuyOrRestoreAtUserAction = false
            
            AppStateProxy.ApplicationProxy
                .completeTransactions
                .subscribe(onNext: { [weak self] in
                    if self?.isBuyOrRestoreAtUserAction == false {
                        restoreTrigger.accept(Void())
                    }
                })
                .disposed(by: disposeBag)
        }
        
        errorView.tapForHide
            .subscribe(onNext: { [weak self] in
                self?.errorView.isHidden = true
            })
            .disposed(by: disposeBag)
    }
}
