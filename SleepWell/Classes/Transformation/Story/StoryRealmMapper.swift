//
//  StoryRealmMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct StoryRealmMapper {
    static func map(from realm: RealmStory) -> Story {
        return Story(id: realm.id,
                     name: realm.name,
                     paid: realm.paid,
                     reader: realm.reader,
                     imagePreviewUrl: URL(string: realm.imagePreviewUrl ?? ""),
                     imageReaderURL: URL(string: realm.imageReaderURL ?? ""),
                     hash: realm.storyHash,
                     length: realm.length)
    }

    static func map(from entity: Story) -> RealmStory {
        return RealmStory(id: entity.id,
                          name: entity.name,
                          paid: entity.paid,
                          reader: entity.reader,
                          imagePreviewUrl: entity.imagePreviewUrl,
                          imageReaderURL: entity.imageReaderURL,
                          storyHash: entity.hash,
                          length: entity.length)
    }
}
