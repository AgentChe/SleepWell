//
//  AmplitudeAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/03/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Amplitude_iOS

final class AmplitudeAnalytics {
    static let shared = AmplitudeAnalytics()
    
    private init() {}
    
    func configure() {
        Amplitude.instance()?.initializeApiKey(GlobalDefinitions.amplitudeAPIKey)
    }
    
    func set(userId: String) {
        Amplitude.instance()?.setUserId(userId)
    }
    
    func set(userAttributes: [String: Any]) {
        Amplitude.instance()?.setUserProperties(userAttributes)
    }
    
    func increment(identity property: String, value: NSObject) {
        let identity = AMPIdentify()
        identity.add(property, value: value)
        Amplitude.instance()?.identify(identity)
    }
    
    func log(with event: AnalyticEvent) {
        Amplitude.instance()?.logEvent(event.name, withEventProperties: event.params)
    }
}
