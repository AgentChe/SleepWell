//
//  UIDeviceExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 05/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

extension UIDevice {
    private static let maxHeightSmallDevice: CGFloat = 1334
     private static let maxHeightVerySmallDevice: CGFloat = 1136
    
    var isSmallScreen: Bool {
        return UIScreen.main.nativeBounds.height <= UIDevice.maxHeightSmallDevice
    }
    
    var isVerySmallScreen: Bool {
        return UIScreen.main.nativeBounds.height <= UIDevice.maxHeightVerySmallDevice
    }
    
    var hasTopNotch: Bool {
        if #available(iOS 11.0,  *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }

        return false
    }
    
    var hasBottomNotch: Bool {
        if #available(iOS 11.0,  *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 > 20
        }

        return false
    }
}
