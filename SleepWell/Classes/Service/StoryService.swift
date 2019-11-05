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
        let request = StoriesListRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { StoriesMapper.parse(response: $0) }
    }

    func getStory(storyId: Int) -> Single<StoryDetail?> {
        let request = StoryDetailRequest(storyId: storyId, userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { StoryDetail.parseFromDictionary(any: $0) }
    }
}
