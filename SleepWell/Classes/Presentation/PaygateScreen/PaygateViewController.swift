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
    
    private let disposeBag = DisposeBag()
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
            })
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: {
                input.completion?(.closed)
                viewModel.dismiss()
            })
            .disposed(by: disposeBag)
        
        Driver<(Bool, PaygateCompletionResult)>
            .merge(buyButton.rx.tap.asDriver().flatMapLatest { _ in viewModel.buy() }.map { ($0, PaygateCompletionResult.purchased) },
                   restorePurchaseButton.rx.tap.asDriver().flatMapLatest { _ in viewModel.restore() }.map { ($0, PaygateCompletionResult.restored) })
            .drive(onNext: { [weak self] stub in
                let (isSuccess, result) = stub
                
                if isSuccess {
                    input.completion?(result)
                    viewModel.dismiss()
                } else {
                    self?.errorView.show(with: "Failed purchase")
                }
            })
            .disposed(by: disposeBag)
        
        errorView.tapForHide
            .subscribe(onNext: { [weak self] in
                self?.errorView.isHidden = true
            })
            .disposed(by: disposeBag)
    }
}