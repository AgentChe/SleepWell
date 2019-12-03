//
//  StoryService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class StoryService {
    func stories() -> Single<[Story]> {
        return RealmDBTransport().loadData(realmType: RealmStory.self, map: { StoryRealmMapper.map(from: $0) })
    }

    func story(storyId: Int) -> Single<StoryDetail?> {
        return RealmDBTransport()
            .loadData(realmType: RealmStoryDetail.self, filter: NSPredicate(format: "id == %i", storyId), map: { StoryDetailRealmMapper.map(from: $0) })
            .map { $0.first }
    }
}
