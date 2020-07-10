//
//  CreateAnonymousRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 10.07.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct CreateAnonymousRequest: APIRequestBody {
    private let gender: Int
    private let pushToken: String
    private let locale: String
    private let version: String
    private let appKey: String
    
    init(gender: Int,
         pushToken: String,
         locale: String,
         version: String,
         appKey: String) {
        self.gender = gender
        self.pushToken = pushToken
        self.locale = locale
        self.version = version
        self.appKey = appKey
    }
    
    var url: String {
        GlobalDefinitions.domainUrl + "/api/users/anonymous"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        [
            "_api_key": GlobalDefinitions.apiKey,
            "gender": gender,
            "push_key": pushToken,
            "locale": locale,
            "version": version,
            "random_string": appKey
        ]
    }
}
