//
//  GetPaygateRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct GetPaygateRequest: APIRequestBody {
    private let userToken: String?
    private let locale: String?
    private let version: String
    
    init(userToken: String?, locale: String?, version: String) {
        self.userToken = userToken
        self.locale = locale
        self.version = version
    }
    
    var url: String {
        var path = GlobalDefinitions.domainUrl + "/api/payments/paygate?_api_key=\(GlobalDefinitions.apiKey)"
        if let userToken = self.userToken {
            path += "&_user_token=\(userToken)"
        }
        
        return path
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params = [
            "version": version
        ]
        
        if let locale = self.locale {
            params["locale"] = locale
        }
        
        return params
    }
}