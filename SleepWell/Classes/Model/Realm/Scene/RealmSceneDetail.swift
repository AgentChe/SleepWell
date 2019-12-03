//
//  RealmSceneDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmSceneDetail: Object {
    @objc var scene: RealmScene!
    let sounds = List<RealmSceneSound>()
    
    convenience init(scene: Scene, sounds: [SceneSound]) {
        self.init()
        
        self.scene = SceneRealmMapper.map(from: scene)
        
        self.sounds.append(objectsIn: sounds.map { SceneSoundRealmMapper.map(from: $0) })
    }
}
