//
//  UIBarButtonItemExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    @IBInspectable var titleLocalize: String? {
        set {
            if let newValue = newValue {
                title = NSLocalizedString(newValue, comment: "")
            }
        }
        get {
            return title
        }
    }
}
