//
//  UIButtonExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

extension UIButton {
    @IBInspectable var textLocalize: String? {
        set {
            if let newValue = newValue {
                setTitle(NSLocalizedString(newValue, comment: ""), for: .normal)
            }
        }
        get {
            return titleLabel?.text
        }
    }
}
