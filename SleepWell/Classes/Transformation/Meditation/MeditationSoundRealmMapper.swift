//
//  RealmMeditationSoundMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct MeditationSoundRealmMapper {
    static func map(from entity: MeditationSound) -> RealmMeditationSound {
        return RealmMeditationSound(id: entity.id,
                                    soundUrl: entity.soundUrl,
                                    soundSecs: entity.soundSecs)
    }
    
    static func map(from realm: RealmMeditationSound) -> MeditationSound {
        return MeditationSound(id: realm.id,
                               soundUrl: URL(string: realm.soundUrl)!,
                               soundSecs: realm.soundSecs)
    }
}
