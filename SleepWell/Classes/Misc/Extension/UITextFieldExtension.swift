//
//  UITextFieldExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

extension UITextField {
    @IBInspectable var textLocalize: String? {
        set {
            if let newValue = newValue {
                text = NSLocalizedString(newValue, comment: "")
            }
        }
        get {
            return text
        }
    }
    
    @IBInspectable var placeholderLocalize: String? {
        set {
            if let newValue = newValue {
                placeholder = NSLocalizedString(newValue, comment: "")
            }
        }
        get {
            return placeholder
        }
    }
}
