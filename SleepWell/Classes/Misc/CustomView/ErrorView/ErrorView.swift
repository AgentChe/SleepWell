//
//  ErrorView.swift
//  Horo
//
//  Created by Andrey Chernyshev on 30/08/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ErrorView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var tryAgainLabel: UILabel!
    
    let tryAgain = PublishRelay<Void>()
    let tapForHide = PublishRelay<Void>()
    
    private let disposeBag = DisposeBag()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        Bundle.main.loadNibNamed("ErrorView", owner: self)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        tryAgainButton.rx.tap
            .bind(to: tryAgain)
            .disposed(by: disposeBag)
        
        let hideGesture = UITapGestureRecognizer()
        addGestureRecognizer(hideGesture)
        hideGesture.rx.event
            .map { _ in Void() }
            .bind(to: tapForHide)
            .disposed(by: disposeBag)
    }
    
    func show(with message: String, canTryAgain: Bool = false) {
        messageLabel.text = message
        tryAgainButton.isHidden = !canTryAgain
        tryAgainLabel.text = canTryAgain ? "try_again".localized : ""
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
}

extension Reactive where Base: ErrorView {
    var showWithMessage: Binder<String> {
        return Binder(base) { base, message in
            base.show(with: message, canTryAgain: false)
        }
    }
    
    var showWithMessageAndTryAgain: Binder<String> {
        return Binder(base) { base, message in
            base.show(with: message, canTryAgain: true)
        }
    }
}
