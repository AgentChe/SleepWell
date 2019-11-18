//
//  SceneService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class SceneService {
    
    func getScene(by id: Int) -> Single<SceneDetail?> {
        let request = SceneDetailRequest(
            sceneId: id,
            userToken: SessionService.userToken,
            apiKey: GlobalDefinitions.apiKey
        )
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { SceneDetail.parseFromDictionary(any: $0) }
    }
}
