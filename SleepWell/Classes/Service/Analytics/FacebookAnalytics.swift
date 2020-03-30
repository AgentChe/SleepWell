//
//  FacebookAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/03/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import FBSDKCoreKit
import RxSwift

final class FacebookAnalytics {
    static let shared = FacebookAnalytics()
    
    private init() {}
    
    func configure() {
        AppEvents.activateApp()
        
        setInitialProperties()
        syncedUserPropertiesWithUserId()
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
    
    private func setInitialProperties() {
        guard !UserDefaults.standard.bool(forKey: "facebook_initial_properties_is_set") else {
            return
        }
        
        set(userAttributes: ["city": "none"])
        
        UserDefaults.standard.set(true, forKey: "facebook_initial_properties_is_set")
    }
    
    private func syncedUserPropertiesWithUserId() {
        guard !UserDefaults.standard.bool(forKey: "facebook_initial_properties_is_synced") else {
            return
        }
        
        _ = Observable
            .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
                   AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .subscribe(onNext: {
                if let userId = SessionService.userId {
                    self.set(userId: "\(userId)")
                }
            })
    }
}
