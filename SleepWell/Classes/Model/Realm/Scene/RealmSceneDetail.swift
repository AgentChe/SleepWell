//
//  RealmSceneDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmSceneDetail: Object {
    @objc dynamic var id: Int = Int.random(in: Int.min...Int.max)
    @objc dynamic var scene: RealmScene!
    let sounds = List<RealmSceneSound>()
    
    convenience init(scene: Scene, sounds: [SceneSound]) {
        self.init()
        
        self.id = scene.id
        self.scene = SceneRealmMapper.map(from: scene)
        
        self.sounds.append(objectsIn: sounds.map { SceneSoundRealmMapper.map(from: $0) })
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
