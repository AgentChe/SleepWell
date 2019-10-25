//
//  PaymentValidateRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct PurchaseValidateRequest: APIRequestBody {
    private let receipt: String?
    private let userToken: String?
    private let version: String?
    
    init(receipt: String?, userToken: String?, version: String?) {
        self.receipt = receipt
        self.userToken = userToken
        self.version = version
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var url: String {
        var path = GlobalDefinitions.domainUrl + "/api/payments/validate?_api_key=\(GlobalDefinitions.apiKey)"
        if let userToken = self.userToken {
            path += "&_user_token=\(userToken)"
        }
        return path
    }
    
    var parameters: Parameters? {
        return ["receipt": receipt ?? "null",
                "version": version ?? "1"]
    }
}
