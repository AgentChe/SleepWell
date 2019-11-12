//
//  StoriesListRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct StoriesListRequest: APIRequestBody {
    private let userToken: String?
    private let apiKey: String
    
    init(userToken: String?, apiKey: String) {
        self.userToken = userToken
        self.apiKey = apiKey
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/stories/list"
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
