//
//  OnboardingStartView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class OnboardingStartView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var getStartedButton: UIButton!
    
    let nextUp = PublishRelay<Void>()
    
    private let disposeBag = DisposeBag()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("OnboardingStartView", owner: self)
        frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        getStartedButton.rx.tap
            .bind(to: nextUp)
            .disposed(by: disposeBag)
    }
    
    func show() {
        AmplitudeAnalytics.shared.log(with: .welcomeScr)
        
        isHidden = false
        alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 1
        })
    }
    
    func hide(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] _ in
            self?.isHidden = true
            
            completion()
        })
    }
}
