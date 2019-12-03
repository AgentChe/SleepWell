//
//  CacheService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class CacheService {
    private let updateMeditations = UpdateMeditations()
    private let updateStories = UpdateStories()
    
    func update() -> Observable<Void> {
        return Observable.combineLatest(updateMeditations.update().catchErrorJustReturn(Void()),
                                        updateStories.update().catchErrorJustReturn(Void())) { _, _ in Void() }
    }
}

private final class UpdateMeditations {
    func update() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: FullMeditationsListRequest(hashCode: CacheHashCodes.meditationsHashCode))
            .asObservable()
            .map { MeditationsMapper.fullMeditations(response: $0) }
            .flatMap { fullMeditations -> Observable<Void> in
                guard let data = fullMeditations else {
                    return .error(RxError.noElements)
                }
                
                let saveMeditations = RealmDBTransport().saveData(entities: data.meditations, map: { MeditationRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! MeditationDetailRealmMapper.map(from: $0) })
                
                return Observable
                    .combineLatest(saveMeditations.asObservable(), saveDetails.asObservable()) { _, _ in Void() }
                    .do(onNext: {
                        CacheHashCodes.meditationsHashCode = data.meditationsHashCode
                    })
            }
    }
}

private final class UpdateStories {
    func update() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: FullStoriesListRequest(hashCode: CacheHashCodes.storiesHashCode))
            .asObservable()
            .map { StoriesMapper.fullStories(response: $0) }
            .flatMap { fullStories -> Observable<Void> in
                guard let data = fullStories else {
                    return .error(RxError.noElements)
                }
                
                let saveStories = RealmDBTransport().saveData(entities: data.stories, map: { StoryRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! StoryDetailRealmMapper.map(from: $0) })
                
                return Observable
                    .combineLatest(saveStories.asObservable(), saveDetails.asObservable()) { _, _ in Void() }
                    .do(onNext: {
                        CacheHashCodes.storiesHashCode = data.storiesHashCode
                    })
            }
    }
}

private final class CacheHashCodes {
    private static let meditationsHashCodeKey = "meditations_hash_code_key"
    private static let storiesHashCodeKey = "stories_hash_code_key"
    private static let scenesHashCodeKey = "scenes_hash_code_key"
    
    static var meditationsHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: meditationsHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: meditationsHashCodeKey)
        }
    }
    
    static var storiesHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: storiesHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: storiesHashCodeKey)
        }
    }
    
    static var scenesHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: scenesHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: scenesHashCodeKey)
        }
    }
}
