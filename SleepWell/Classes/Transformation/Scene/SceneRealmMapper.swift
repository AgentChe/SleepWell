//
//  SceneRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct SceneRealmMapper {
    static func map(from entity: Scene) -> RealmScene {
        return RealmScene(id: entity.id,
                          paid: entity.paid,
                          imageUrl: entity.imageUrl,
                          hash: entity.hash)
    }
    
    static func map(from realm: RealmScene) -> Scene {
        return Scene(id: realm.id,
                     paid: realm.paid,
                     imageUrl: URL(string: realm.imageUrl ?? ""),
                     hash: realm.hashCode)
    }
}
