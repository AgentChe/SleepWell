//
//  PremiumUnlockCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 27/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class PremiumUnlockCell: UITableViewCell {
    @IBOutlet private var gradientView: GradientView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        gradientView.gradientLayer.colors = [UIColor(red: 0.3, green: 0.61, blue: 0.86, alpha: 1).cgColor, UIColor(red: 0.58, green: 0.57, blue: 0.96, alpha: 0).cgColor]
        gradientView.gradientLayer.locations = [0, 1]
        gradientView.gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradientView.gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
    }
}

