//
//  UIDeviceUtils.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSLocale
import UIKit

extension UIDevice {
    static var deviceLanguageCode: String? {
        guard let mainPreferredLanguage = Locale.preferredLanguages.first else {
            return nil
        }
        
        return Locale(identifier: mainPreferredLanguage).languageCode
    }
}
