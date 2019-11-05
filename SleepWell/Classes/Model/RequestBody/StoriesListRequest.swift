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
        var path = GlobalDefinitions.domainUrl + "/api/stories/list?_api_key=\(GlobalDefinitions.apiKey)"
        if let userToken = self.userToken {
            path += "&_user_token=\(userToken)"
        }
        
        return path
    }

    var method: HTTPMethod {
        return .post
    }
}
