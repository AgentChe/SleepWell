//
//  NoiseCategoryRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

final class NoiseCategoryRealmMapper {
    static func map(from entity: NoiseCategory) -> RealmNoiseCategory {
        return RealmNoiseCategory(id: entity.id,
                                  name: entity.name,
                                  sort: entity.sort,
                                  noises: entity.noises)
    }
    
    static func map(from realm: RealmNoiseCategory) -> NoiseCategory {
        return NoiseCategory(id: realm.id,
                             name: realm.name,
                             sort: realm.sort,
                             noises: realm.noises.map { NoiseRealmMapper.map(from: $0) })
    }
}
