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
                    Analytics.shared.setUserId(userId: userId)
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
                
                Analytics.shared.setUserAttributes(attributes: properties)
            })
    }
    
    private func setAudioProperties() {
        _ = AudioPlayerService.shared.didTapPlayRecording
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    Analytics.shared.updateUserAttribute(property: "meditations started", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    Analytics.shared.updateUserAttribute(property: "stories started", value: 1 as NSObject)
                }
            })
        
        _ = AudioPlayerService.shared.playingForTwentySeconds
            .emit(onNext: { recording in
                if let _ = recording as? MeditationDetail {
                    Analytics.shared.updateUserAttribute(property: "meditations 20sec", value: 1 as NSObject)
                }
                
                if let _ = recording as? StoryDetail {
                    Analytics.shared.updateUserAttribute(property: "stories 20sec", value: 1 as NSObject)
                }
            })
    }
}
