//
//  GetNoiseCategoriesRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct GetNoiseCategoriesRequest: APIRequestBody {
    private let hashCode: String?
    
    init(hashCode: String?) {
        self.hashCode = hashCode
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/sounds/categories?_api_key=\(GlobalDefinitions.apiKey)"
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        if let hashCode = self.hashCode {
            return ["hash": hashCode]
        }
        
        return nil
    }
}
