//
//  SessionService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class SessionService {
    private static let userTokenKey = "user_token_key"
    
    static var userToken: String? {
        return UserDefaults.standard.string(forKey: SessionService.userTokenKey)
    }
    
    static func store(userToken: String?) {
        UserDefaults.standard.set(userToken, forKey: SessionService.userTokenKey)
    }
    
    func check(userToken: String) -> Single<Session?> {
        return RestAPITransport()
            .callServerApi(requestBody: CheckUserTokenRequest(userToken: userToken))
            .map { Session.parseFromDictionary(any: $0) }
    }
}
