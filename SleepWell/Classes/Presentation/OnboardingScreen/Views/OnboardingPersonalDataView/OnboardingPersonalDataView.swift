//
//  OnboardingPersonalDataView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class OnboardingPersonalDataView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var maleCheckView: CheckView!
    @IBOutlet weak var femaleCheckView: CheckView!
    @IBOutlet weak var otherCheckView: CheckView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("OnboardingPersonalDataView", owner: self)
        frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
    }
    
    func show() {
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
