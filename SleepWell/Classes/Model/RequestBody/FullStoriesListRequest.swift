//
//  StoriesListRequest.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct FullStoriesListRequest: APIRequestBody {
    private let hashCode: String?
    
    init(hashCode: String?) {
        self.hashCode = hashCode
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/stories/all"
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
