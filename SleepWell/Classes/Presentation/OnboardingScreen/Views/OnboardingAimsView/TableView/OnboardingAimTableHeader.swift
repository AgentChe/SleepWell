//
//  OnboardingAimTableHeader.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class OnboardingAimTableHeader: UIView {
    private lazy var whatHelpLabel: UILabel = {
        let attr = TextAttributes()
            .font(Font.Poppins.bold(size: 34))
            .lineHeight(41)
            .textAlignment(.center)
            .textColor(.white)
        
        let label = UILabel()
        label.attributedText = "what_to_help_you_with".localized.attributed(with: attr)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var selectAimsLabel: UILabel = {
        let attr = TextAttributes()
            .font(Font.Poppins.medium(size: 17))
            .lineHeight(22)
            .letterSpacing(-0.5)
            .textAlignment(.center)
            .textColor(UIColor.white.withAlphaComponent(0.7))
        
        let label = UILabel()
        label.attributedText = "select_that_are_the_most_relevant_to_you".localized.attributed(with: attr)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        
        addSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        addSubviews()
    }
    
    private func addSubviews() {
        addSubview(whatHelpLabel)
        addSubview(selectAimsLabel)
        
        whatHelpLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40).isActive = true
        whatHelpLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34).isActive = true
        whatHelpLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -34).isActive = true
        
        selectAimsLabel.topAnchor.constraint(equalTo: whatHelpLabel.bottomAnchor, constant: 8).isActive = true
        selectAimsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34).isActive = true
        selectAimsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -34).isActive = true
        selectAimsLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30).isActive = true
    }
}
