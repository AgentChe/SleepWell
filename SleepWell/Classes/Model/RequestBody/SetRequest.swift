//
//  SetRequest.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 31/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Alamofire

struct SetRequest: APIRequestBody {
    private let userToken: String
    private let aims: [Aim]?
    private let gender: Gender?
    private let birthYear: Int?
    private let pushToken: String?
    private let pushTime: String?
    private let isPushEnabled: Bool?
    private let locale: String?
    private let version: String?
    private let timezone: String?
    
    init(userToken: String,
         personalData: PersonalData,
         locale: String? = nil,
         version: String? = nil,
         timezone: String? = nil) {
        self.userToken = userToken
        self.aims = personalData.aims
        self.gender = personalData.gender
        self.birthYear = personalData.birthYear
        self.pushToken = personalData.pushToken
        self.pushTime = personalData.pushTime
        self.isPushEnabled = personalData.pushIsEnabled
        self.locale = locale
        self.version = version
        self.timezone = timezone
    }
    
    var url: String {
        return GlobalDefinitions.domainUrl + "/api/users/set?_api_key=\(GlobalDefinitions.apiKey)&_user_token=\(userToken)"
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        var params: [String: Any] = [:]
        
        if let aims = self.aims?.map({ $0.rawValue }) {
            params["aims"] = aims
        }
        
        if let gender = self.gender?.rawValue {
            params["gender"] = gender
        }
        
        if let birthYear = self.birthYear {
            params["birth_year"] = birthYear
        }
        
        if let pushToken = self.pushToken {
            params["push_key"] = pushToken
        }
        
        if let pushTime = self.pushTime {
            params["push_time"] = pushTime
        }
        
        if let isPushEnabled = self.isPushEnabled {
            params["push_notifications"] = isPushEnabled
        }
        
        if let locale = self.locale {
            params["locale"] = locale
        }
        
        if let version = self.version {
            params["version"] = version
        }
        
        if let timezone = self.timezone {
            params["timezone"] = timezone
        }
        
        return params
    }
}
