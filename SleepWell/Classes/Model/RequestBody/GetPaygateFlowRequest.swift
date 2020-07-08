//
//  GetPaygateFlowRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 08.07.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct GetPaygateFlowRequest: APIRequestBody {
    private let version: String
    
    init(version: String) {
        self.version = version
    }
    
    var url: String {
        GlobalDefinitions.domainUrl + "/api/payments/flow"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        [
            "_api_key": GlobalDefinitions.apiKey,
            "version": version
        ]
    }
}
