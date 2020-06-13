//
//  PaygatePingRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 12/06/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct PaygatePingRequest: APIRequestBody {
    private let randomKey: String
    
    init(randomKey: String) {
        self.randomKey = randomKey
    }
    
    var url: String {
        GlobalDefinitions.domainUrl + "/api/payments/ping?_api_key=\(GlobalDefinitions.apiKey)"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        [
            "random_string": randomKey
        ]
    }
}

