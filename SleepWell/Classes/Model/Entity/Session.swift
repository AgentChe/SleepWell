//
//  Session.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

struct Session: Model {
    let userToken: String?
    let activeSubscription: Bool
    let userId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case data = "_data"
    }
    
    private enum DataKeys: String, CodingKey {
        case userToken = "user_token"
        case activeSubscription = "active_subscription"
        case userId = "user_id"
    }
    
    init(userToken: String?, activeSubscription: Bool, userId: Int?) {
        self.userToken = userToken
        self.activeSubscription = activeSubscription
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let data = try container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        userToken = try data.decode(String?.self, forKey: .userToken)
        activeSubscription = try data.decode(Bool.self, forKey: .activeSubscription)
        userId = try data.decode(Int?.self, forKey: .userId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        var data = container.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        try data.encode(userToken, forKey: .userToken)
        try data.encode(activeSubscription, forKey: .activeSubscription)
        try data.encode(userId, forKey: .userId)
    }
}
