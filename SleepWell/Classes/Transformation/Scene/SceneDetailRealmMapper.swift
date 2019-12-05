//
//  SceneDetailRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

struct SceneDetailRealmMapper {
    static func map(from entity: SceneDetail) -> RealmSceneDetail {
        return RealmSceneDetail(scene: entity.scene, sounds: entity.sounds)
    }
    
    static func map(from realm: RealmSceneDetail) -> SceneDetail {
        return SceneDetail(scene: SceneRealmMapper.map(from: realm.scene),
                           sounds: realm.sounds.map { SceneSoundRealmMapper.map(from: $0) })
    }
}
