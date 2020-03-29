//
//  FacebookAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/03/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import FBSDKCoreKit

final class FacebookAnalytics {
    static let shared = FacebookAnalytics()
    
    private init() {}
    
    func configure() {
        AppEvents.activateApp()
    }
    
    func set(userId: String) {
        AppEvents.userID = userId
    }
    
    func set(userAttributes: [String: Any]) {
        AppEvents.updateUserProperties(userAttributes)
    }
    
    func logPurchase(amount: Double, currency: String) {
        AppEvents.logPurchase(amount, currency: currency)
    }
}
