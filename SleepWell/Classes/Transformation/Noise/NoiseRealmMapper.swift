//
//  NoiseRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

final class NoiseRealmMapper {
    static func map(from entity: Noise) -> RealmNoise {
        return RealmNoise(id: entity.id,
                          name: entity.name,
                          paid: entity.paid,
                          noiseCategoryId: entity.noiseCategoryId,
                          imageUrl: entity.imageUrl.absoluteString,
                          sounds: entity.sounds,
                          hashCode: entity.hash,
                          sort: entity.sort)
    }
    
    static func map(from realm: RealmNoise) -> Noise {
        return Noise(id: realm.id,
                     name: realm.name,
                     paid: realm.paid,
                     noiseCategoryId: realm.noiseCategoryId,
                     imageUrl: URL(string: realm.imageUrl)!,
                     sounds: realm.sounds.map { NoiseSoundRealmMapper.map(from: $0)},
                     sort: realm.sort,
                     hash: realm.hashCode)
    }
}
