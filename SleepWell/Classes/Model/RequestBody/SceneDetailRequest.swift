//
//  SceneDetailRequest.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct SceneDetailRequest: APIRequestBody {
    
    private let sceneId: Int
    private let userToken: String?
    private let apiKey: String
    
    init(sceneId: Int, userToken: String?, apiKey: String) {
        self.sceneId = sceneId
        self.userToken = userToken
        self.apiKey = apiKey
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/scenes/get"
    }

    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String : Any] = [
            "_api_key": apiKey,
            "scene_id": sceneId
        ]
        if let token = userToken {
            params["_user_token"] = token
        }
        return params
    }
}
