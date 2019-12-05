//
//  MeditationTagRealmMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct MeditationTagRealmMapper {
    static func map(from realm: RealmMeditationTag) -> MeditationTag {
        return MeditationTag(id: realm.id, name: realm.name, meditationsCount: realm.meditationsCount)
    }

    static func map(from entity: MeditationTag) -> RealmMeditationTag {
        return RealmMeditationTag(id: entity.id, name: entity.name, meditationsCount: entity.meditationsCount)
    }
}
