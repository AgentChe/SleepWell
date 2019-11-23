//
//  SceneService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class SceneService {

    func scenes() -> Single<[Scene]> {
        let request = ScenesRequest(
            userToken: SessionService.userToken,
            apiKey: GlobalDefinitions.apiKey
        )
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { ScenesMapper.parse(response: $0) }
    }
    
    func getScene(by id: Int) -> Single<SceneDetail?> {
        let request = SceneDetailRequest(
            sceneId: id,
            userToken: SessionService.userToken,
            apiKey: GlobalDefinitions.apiKey
        )
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { response -> SceneDetail? in
                if try CheckResponseForNeedPaymentError.isNeedPayment(jsonResponse: response) {
                    throw NSError(domain: "SceneService", code: 403, userInfo: [:])
                } else {
                    return SceneDetail.parseFromDictionary(any: response)
                }
            }
    }
}
