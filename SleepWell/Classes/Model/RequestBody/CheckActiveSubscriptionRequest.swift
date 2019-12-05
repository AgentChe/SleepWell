//
//  CheckActiveSubscriptionRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 05/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct CheckActiveSubscriptionRequest: APIRequestBody {
    private let userToken: String?
    private let meditationId: Int
    
    init(userToken: String?, meditationId: Int) {
        self.userToken = userToken
        self.meditationId = meditationId
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/meditations/check"
    }
    
    var parameters: Parameters? {
        var params: Parameters = ["meditation_id": meditationId,
                                  "_api_key": GlobalDefinitions.apiKey]
        
        if let userToken = self.userToken {
            params["_user_token"] = userToken
        }
        
        return params
    }
    
    var method: HTTPMethod {
        return .post 
    }
}
