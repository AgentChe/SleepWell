//
//  HeaderTitleView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class HeaderTitleView: UIView {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var conteinerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func setup(title: String, subtitle: String) {
        titleLabel.text = title
        descriptionLabel.text = subtitle
        
    }
    
    private func initialize() {
        UINib(nibName: "HeaderTitleView", bundle: nil).instantiate(withOwner: self, options: nil)
        conteinerView.frame = bounds
        addSubview(conteinerView)
    }
}
