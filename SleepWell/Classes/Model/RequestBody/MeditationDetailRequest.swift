//
//  MeditationDetailRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct MeditationDetailRequest: APIRequestBody {
    private let userToken: String?
    private let apiKey: String
    private let meditationId: Int
    
    init(meditationId: Int, userToken: String?, apiKey: String) {
        self.meditationId = meditationId
        self.userToken = userToken
        self.apiKey = apiKey
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/meditations/get"
    }

    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String : Any] = ["_api_key": apiKey,
                                      "meditation_id": meditationId]
        if let token = userToken {
            params["_user_token"] = token
        }
        return params
    }
}
