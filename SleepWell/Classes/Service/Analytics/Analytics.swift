//
//  Analytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Amplitude_iOS
import FBSDKCoreKit

final class Analytics {
    static let shared = Analytics()
    
    private init() {}
    
    func configure() {
        Amplitude.instance()?.initializeApiKey(GlobalDefinitions.analyticsAPIKey)
        AttributionAPIService.shared.configure()
        IDFAService.shared.configure()
        UserAnalytics.shared.configure()
    }
    
    func setUserId(userId: Int) {
        Amplitude.instance()?.setUserId("\(userId)")
        
        AppEvents.activateApp()
        AppEvents.userID = "\(userId)"
    }
    
    func setUserAttributes(attributes: [String: Any]) {
        Amplitude.instance()?.setUserProperties(attributes)
        AppEvents.updateUserProperties(["city":"none"])
    }
    
    func updateUserAttribute(property: String, value: NSObject) {
        let identity = AMPIdentify()
        identity.add(property, value: value)
        Amplitude.instance()?.identify(identity)
    }
    
    func log(with event: AnalyticEvent) {
        if let params = event.params {
            Amplitude.instance()?.logEvent(event.name, withEventProperties: params)
        } else {
            Amplitude.instance()?.logEvent(event.name)
        }
    }
    
    func logFBAboutPurchase() {
        AppEvents.logPurchase(0, currency: "USD", parameters: [:])
    }
}
