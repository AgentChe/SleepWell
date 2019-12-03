//
//  MeditationDetailRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSError

struct MeditationDetailRealmMapper {
    static func map(from meditation: MeditationDetail) throws -> RealmMeditationDetail {
        guard
            let recording = meditation.recording as? Meditation,
            let readingSound = meditation.readingSound as? MeditationSound
        else {
            throw NSError(domain: "MeditationDetailRealmMapper", code: 0, userInfo: [:])
        }
        
        let ambientSound = meditation.ambientSound as? MeditationSound
        
        return RealmMeditationDetail(recording: recording, readingSound: readingSound, ambientSound: ambientSound)
    }
    
    static func map(from realm: RealmMeditationDetail) -> MeditationDetail {
        var ambientSound: MeditationSound? = nil
        if let realmAmbientSound = realm.ambientSound {
            ambientSound = MeditationSoundRealmMapper.map(from: realmAmbientSound)
        }
        
        return MeditationDetail(recording: MeditationRealmMapper.map(from: realm.recording),
                                readingSound: MeditationSoundRealmMapper.map(from: realm.readingSound),
                                ambientSound: ambientSound)
    }
}
