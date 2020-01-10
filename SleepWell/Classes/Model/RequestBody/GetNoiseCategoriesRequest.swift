//
//  GetNoiseCategoriesRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct GetNoiseCategoriesRequest: APIRequestBody {
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/sounds/categories"
    }
    
    var method: HTTPMethod {
        return .post
    }

    var parameters: Parameters? {
        return [
            "_api_key": GlobalDefinitions.apiKey
        ]
    }
}
