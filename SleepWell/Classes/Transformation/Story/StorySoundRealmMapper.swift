//
//  StorySoundRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct StorySoundRealmMapper {
    static func map(from entity: StorySound) -> RealmStorySound {
        return RealmStorySound(id: entity.id,
                               soundUrl: entity.soundUrl,
                               soundSecs: entity.soundSecs)
    }
    
    static func map(from realm: RealmStorySound) -> StorySound {
        return StorySound(id: realm.id,
                          soundUrl: URL(string: realm.soundUrl)!,
                          soundSecs: realm.soundSecs)
    }
}
