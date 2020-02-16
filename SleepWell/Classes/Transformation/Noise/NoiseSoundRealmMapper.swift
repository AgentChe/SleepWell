//
//  NoiseSoundRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

final class NoiseSoundRealmMapper {
    static func map(from entity: NoiseSound) -> RealmNoiseSound {
        return RealmNoiseSound(id: entity.id,
                               soundUrl: entity.soundUrl,
                               soundSecs: entity.soundSecs)
    }
    
    static func map(from realm: RealmNoiseSound) -> NoiseSound {
        return NoiseSound(id: realm.id,
                          soundUrl: URL(string: realm.soundUrl)!,
                          soundSecs: realm.soundSecs)
    }
}
