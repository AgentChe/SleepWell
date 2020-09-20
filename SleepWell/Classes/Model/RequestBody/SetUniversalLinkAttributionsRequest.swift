//
//  SetUniversalLinkAttributionsRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20.09.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct SetUniversalLinkAttributionsRequest: APIRequestBody {
    private let appKey: String
    private let channel: String?
    private let campaign: String?
    private let adgroup: String?
    private let feature: String?
    
    init(appKey: String,
         channel: String? = nil,
         campaign: String? = nil,
         adgroup: String? = nil,
         feature: String? = nil) {
        self.appKey = appKey
        self.channel = channel
        self.campaign = campaign
        self.adgroup = adgroup
        self.feature = feature
    }
    
    var url: String {
        GlobalDefinitions.domainUrl + "/api/attribution"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var parameters: Parameters? {
        var params: Parameters = [
            "_api_key": GlobalDefinitions.apiKey,
            "random_string": appKey
        ]
        
        if let channel = channel {
            params["channel"] = channel
        }
        
        if let campaign = campaign {
            params["campaign"] = campaign
        }
        
        if let adgroup = adgroup {
            params["adgroup"] = adgroup
        }
        
        if let feature = feature {
            params["feature"] = feature
        }
        
        return params
    }
}
