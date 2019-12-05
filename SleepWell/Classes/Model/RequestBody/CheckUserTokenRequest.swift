//
//  CheckUserTokenRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct CheckUserTokenRequest: APIRequestBody {
    private let userToken: String
    
    init(userToken: String) {
        self.userToken = userToken
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/check/user_token?_api_key=\(GlobalDefinitions.apiKey)&_user_token=\(userToken)"
    }
    
    var method: HTTPMethod {
        return .post
    }
}
