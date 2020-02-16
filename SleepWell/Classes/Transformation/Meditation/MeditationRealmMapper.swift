//
//  MeditationRealmMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct MeditationRealmMapper {
    static func map(from realm: RealmMeditation) -> Meditation {
        return Meditation(id: realm.id,
                          name: realm.name,
                          paid: realm.paid,
                          reader: realm.reader,
                          imagePreviewUrl: URL(string: realm.imagePreviewURL ?? ""),
                          imageReaderURL: URL(string: realm.imageReaderURL ?? ""),
                          hash: realm.meditationHash,
                          tags: Array(realm.tags),
                          length: realm.length,
                          sort: realm.sort)
    }

    static func map(from entity: Meditation) -> RealmMeditation {
        return RealmMeditation(id: entity.id,
                               name: entity.name,
                               paid: entity.paid,
                               reader: entity.reader,
                               imagePreviewURL: entity.imagePreviewUrl,
                               imageReaderURL: entity.imageReaderURL,
                               meditationHash: entity.hash,
                               tags: entity.tags,
                               length: entity.length,
                               sort: entity.sort)
    }
}
