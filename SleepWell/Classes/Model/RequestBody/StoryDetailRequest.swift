//
//  StoryDetailRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct StoryDetailRequest: APIRequestBody {
    private let userToken: String?
    private let apiKey: String
    private let storyId: Int
    
    init(storyId: Int, userToken: String?, apiKey: String) {
        self.storyId = storyId
        self.userToken = userToken
        self.apiKey = apiKey
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/stories/get"
    }

    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String : Any] = ["_api_key": apiKey,
                                      "story_id": storyId]
        if let token = userToken {
            params["_user_token"] = token
        }
           return params
    }
}
