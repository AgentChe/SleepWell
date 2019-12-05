//
//  ScenesRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct FullScenesListRequest: APIRequestBody {
    private let hashCode: String?
    
    init(hashCode: String?) {
        self.hashCode = hashCode
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/scenes/all"
    }

    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String : Any] = ["_api_key": GlobalDefinitions.apiKey]
        if let hashCode = self.hashCode {
            params["hash"] = hashCode
        }
        return params
    }
}
