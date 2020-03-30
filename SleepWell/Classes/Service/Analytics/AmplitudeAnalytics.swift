//
//  AmplitudeAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/03/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Amplitude_iOS
import iAd
import RxSwift

final class AmplitudeAnalytics {
    static let shared = AmplitudeAnalytics()
    
    private init() {}
    
    func configure() {
        Amplitude.instance()?.initializeApiKey(GlobalDefinitions.amplitudeAPIKey)
        
        setInitialProperties()
        setAudioProperties()
        syncedUserPropertiesWithUserId()
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
    
    private func setInitialProperties() {
        guard !UserDefaults.standard.bool(forKey: "amplitude_initial_properties_is_set") else {
            return
        }
        
        ADClient.shared().requestAttributionDetails { details, _ in
            var userAttributes = details?.first?.value as? [String: Any] ?? [:]
            userAttributes["app"] = GlobalDefinitions.appNameForAmplitude
            userAttributes["IDFA"] = IDFAService.shared.getIDFA()
            userAttributes["ad_tracking"] = IDFAService.shared.isAdvertisingTrackingEnabled() ? "idfa enabled" : "idfa disabled"
            
            self.set(userAttributes: userAttributes)
            
            self.log(with: .firstLaunch)
            
            if userAttributes["iad-attribution"] as? String == "true" {
                self.log(with: .searchAdsInstall)
            }
            
            UserDefaults.standard.set(true, forKey: "amplitude_initial_properties_is_set")
        }
    }
    
    private func setAudioProperties() {
        _ = AudioPlayerService.shared.didTapPlayRecording
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    self.increment(identity: "meditations started", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    self.increment(identity: "stories started", value: 1 as NSObject)
                }
            })
        
        _ = AudioPlayerService.shared.playingForTwentySeconds
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    self.increment(identity: "meditations 20sec", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    self.increment(identity: "stories 20sec", value: 1 as NSObject)
                }
            })
    }
    
    private func syncedUserPropertiesWithUserId() {
        guard !UserDefaults.standard.bool(forKey: "amplitude_initial_properties_is_synced") else {
            return
        }
        
        _ = Observable
            .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
                   AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .flatMapLatest { self.getPersonalDataProperties() }
            .subscribe(onNext: { properties in
                self.set(userAttributes: properties)
                
                if let userId = SessionService.userId {
                    self.set(userId: String(format: "%@_%i", GlobalDefinitions.appNameForAmplitude, userId))
                }
                
                self.log(with: .userIdSynced)
                
                UserDefaults.standard.set(true, forKey: "amplitude_initial_properties_is_synced")
            })
    }
    
    private func getPersonalDataProperties() -> Single<[String: Any]> {
        func map(gender: Gender?) -> String? {
            guard let gender = gender else {
                return nil
            }
            
            switch gender {
            case .female:
                return "female"
            case .male:
                return "male"
            case .other:
                return "other"
            }
        }
        
        return getPersonalData()
            .map { data in
                [
                    "birth year": data?.birthYear ?? -1,
                    "gender": map(gender: data?.gender) ?? "nil",
                    "bedtime": data?.pushTime ?? "nil",
                    "push access": data?.pushIsEnabled ?? false
                ]
            }
    }
    
    private func getPersonalData() -> Single<PersonalData?> {
        if let cachedPersonalData = PersonalDataService.cachedPersonalData() {
            return .just(cachedPersonalData)
        }
        
        return PersonalDataService
            .downloadPersonalData()
            .catchErrorJustReturn(nil)
    }
}
