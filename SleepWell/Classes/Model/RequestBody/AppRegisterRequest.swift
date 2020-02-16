//
//  AppRegisterRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct AppRegisterRequest: APIRequestBody {
    private let idfa: String
    private let randomKey: String
    private let version: String
    private let attributions: [String: NSObject]?
    
    init(idfa: String, randomKey: String, version: String, attributions: [String: NSObject]?) {
        self.idfa = idfa
        self.randomKey = randomKey
        self.version = version
        self.attributions = attributions
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/app_installs/register?_api_key=\(GlobalDefinitions.apiKey)"
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var result = attributions ?? [:]
        result["idfa"] = idfa as NSObject
        result["random_string"] = randomKey as NSObject
        result["version"] = version as NSObject
        return result
    }
}
