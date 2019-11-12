//
//  StoryService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class StoryService {
    func stories() -> Observable<[Story]> {
        let cachStories = RealmDBTransport()
            .loadData(realmType: RealmStory.self) {
                StoryRealmMapper.map(from: $0)
            }

        
        let request = StoriesListRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)

        let stories = RestAPITransport()
            .callServerApi(requestBody: request)
            .map { StoriesMapper.parse(response: $0) }
            .flatMap {
                RealmDBTransport().saveData(entities: $0) {
                    StoryRealmMapper.map(from: $0)
                }
            }
        .flatMap {
            cachStories
        }
        .catchError { _ in
            cachStories
        }

        return Observable.concat(cachStories.asObservable(), stories.asObservable())
    }

    func getStory(storyId: Int) -> Single<StoryDetail?> {
        let request = StoryDetailRequest(storyId: storyId, userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { StoryDetail.parseFromDictionary(any: $0) }
    }
}
