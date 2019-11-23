//
//  ScenesRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct ScenesRequest: APIRequestBody {

    private let userToken: String?
    private let apiKey: String
    
    init(userToken: String?, apiKey: String) {
        self.userToken = userToken
        self.apiKey = apiKey
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/scenes/list"
    }

    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String : Any] = ["_api_key": apiKey]
        if let token = userToken {
            params["_user_token"] = token
        }
        return params
    }
}