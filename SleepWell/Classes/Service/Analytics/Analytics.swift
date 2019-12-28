//
//  Analytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Amplitude_iOS

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
    }
    
    func setUserAttributes(attributes: [String: Any]) {
        Amplitude.instance()?.setUserProperties(attributes)
    }
    
    func updateUserAttribute(property: String, value: NSObject) {
        let identity = AMPIdentify()
        identity.add(property, value: value)
        Amplitude.instance()?.identify(identity)
    }
    
    func log(with event: AnalyticEvent) {
        Amplitude.instance()?.logEvent(event.name)
    }
}
