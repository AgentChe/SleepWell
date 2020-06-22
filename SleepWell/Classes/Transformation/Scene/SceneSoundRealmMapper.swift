//
//  SceneSoundRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct SceneSoundRealmMapper {
    static func map(from entity: SceneSound) -> RealmSceneSound {
        return RealmSceneSound(id: entity.id,
                               name: entity.name,
                               soundUrl: entity.soundUrl,
                               soundSecs: entity.soundSecs,
                               defaultVolume: entity.defaultVolume)
    }
    
    static func map(from realm: RealmSceneSound) -> SceneSound {
        return SceneSound(id: realm.id,
                          name: realm.name,
                          soundUrl: URL(string: realm.soundUrl)!,
                          soundSecs: realm.soundSecs,
                          defaultVolume: realm.defaultVolume)
    }
}
