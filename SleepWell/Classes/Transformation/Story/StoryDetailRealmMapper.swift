//
//  StoryDetailRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSError

struct StoryDetailRealmMapper {
    static func map(from story: StoryDetail) throws -> RealmStoryDetail {
        guard
            let recording = story.recording as? Story,
            let readingSound = story.readingSound as? StorySound,
            let ambientSound = story.ambientSound as? StorySound
        else {
            throw NSError(domain: "StoryDetailRealmMapper", code: 0, userInfo: [:])
        }
        
        return RealmStoryDetail(recording: recording, readingSound: readingSound, ambientSound: ambientSound)
    }
    
    static func map(from realm: RealmStoryDetail) -> StoryDetail {
        var ambientSound: StorySound? = nil
        if let realmAmbientSound = realm.ambientSound {
            ambientSound = StorySoundRealmMapper.map(from: realmAmbientSound)
        }
        
        return StoryDetail(recording: StoryRealmMapper.map(from: realm.recording),
                           readingSound: StorySoundRealmMapper.map(from: realm.readingSound),
                           ambientSound: ambientSound)
    }
}
