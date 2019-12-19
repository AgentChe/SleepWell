//
//  RateService.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 16/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import StoreKit

final class RateManager {
    
    static func incrementRun() {
        let count = UserDefaults.standard.integer(forKey: runCountKey)
        if count < 3 {
            UserDefaults.standard.set(count + 1, forKey: runCountKey)
        }
    }
    
    static func secondLaunch() {
        let count = UserDefaults.standard.integer(forKey: runCountKey)
        if count == 2 {
            showRateController()
        }
    }
    
    static func showRateController() {
        if let lastDate = (UserDefaults.standard.object(forKey: weekReteKey) as? Date)?.daysSinceNow.day {
            if lastDate > 7 {
                showRateAlert()
            }
        } else {
            showRateAlert()
        }
    }
    
    private static func showRateAlert() {
        SKStoreReviewController.requestReview()
        UserDefaults.standard.setValue(Date(), forKey: weekReteKey)
    }
    
    private static let runCountKey = "kRunCount"
    private static let weekReteKey = "kWeekKey"
}

extension Date {
    var daysSinceNow: DateComponents {
        let now = Date()
        return Calendar.current.dateComponents([.day], from: self, to: now)
    }
}
