//
//  MeditationService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class MeditationService {
    func meditations() -> Single<[Meditation]> {
        let request = MeditationsListRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { MeditationsMapper.parse(response: $0) }
    }
    
    func getMeditation(meditationId: Int) -> Single<MeditationDetail?> {
        let request = MeditationDetailRequest(meditationId: meditationId, userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { MeditationDetail.parseFromDictionary(any: $0) }
    }
    
    func getTags() -> Single<[MeditationTag]> {
        let request = MeditationTagsRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { TagsMapper.parse(response: $0) }
    }
}
