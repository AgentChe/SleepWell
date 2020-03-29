//
//  UserAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class UserAnalytics {
    static let shared = UserAnalytics()
    
    private init() {}
    
    func configure() {
        setUserProperties()
        setAudioProperties()
    }
    
    private func setUserProperties() {
        _ = Observable
        .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
               AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .flatMapLatest { _ -> Single<PersonalData?> in
                if let cachedPersonalData = PersonalDataService.cachedPersonalData() {
                    return .just(cachedPersonalData)
                }
                
                return PersonalDataService.downloadPersonalData().catchErrorJustReturn(nil)
            }
            .subscribe(onNext: { personalData in
                if let userId = SessionService.userId {
                    AmplitudeAnalytics.shared.set(userId: "\(userId)")
                    FacebookAnalytics.shared.set(userId: "\(userId)")
                }
                
                guard let personalData = personalData else {
                    return
                }
                
                func map(gender: Gender) -> String {
                    switch gender {
                    case .female:
                        return "female"
                    case .male:
                        return "male"
                    case .other:
                        return "other"
                    }
                }
                
                let properties: [String: Any] = [
                    "birth year": personalData.birthYear,
                    "gender": map(gender: personalData.gender),
                    "bedtime": personalData.pushTime ?? "",
                    "push access": personalData.pushIsEnabled
                ]
                
                AmplitudeAnalytics.shared.set(userAttributes: properties)
                FacebookAnalytics.shared.set(userAttributes: ["city": "none"])
            })
    }
    
    private func setAudioProperties() {
        _ = AudioPlayerService.shared.didTapPlayRecording
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    AmplitudeAnalytics.shared.increment(identity: "meditations started", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    AmplitudeAnalytics.shared.increment(identity: "stories started", value: 1 as NSObject)
                }
            })
        
        _ = AudioPlayerService.shared.playingForTwentySeconds
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    AmplitudeAnalytics.shared.increment(identity: "meditations 20sec", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    AmplitudeAnalytics.shared.increment(identity: "stories 20sec", value: 1 as NSObject)
                }
            })
    }
}
