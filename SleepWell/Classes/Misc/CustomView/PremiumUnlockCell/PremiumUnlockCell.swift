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
        gradientView.gradientLayer.colors = [UIColor(red: 76 / 255, green: 156 / 255, blue: 220 / 255, alpha: 1).cgColor,
                                             UIColor(red: 148 / 255, green: 146 / 255, blue: 245 / 255, alpha: 0).cgColor]
        gradientView.gradientLayer.locations = [0, 1]
        gradientView.gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientView.gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
    }
}
