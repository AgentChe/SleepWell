//
//  SessionService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class SessionService {
    private static let userTokenKey = "user_token_key"
    private static let userIdKey = "user_id_key"
    
    static var userToken: String? {
        return UserDefaults.standard.string(forKey: SessionService.userTokenKey)
    }
    
    static var userId: Int? {
        return UserDefaults.standard.integer(forKey: SessionService.userIdKey)
    }
    
    static func store(session: Session?) {
        UserDefaults.standard.set(session?.userToken, forKey: SessionService.userTokenKey)
        UserDefaults.standard.set(session?.userId, forKey: SessionService.userIdKey)
    }
    
    func check(userToken: String) -> Single<Session?> {
        return RestAPITransport()
            .callServerApi(requestBody: CheckUserTokenRequest(userToken: userToken))
            .map { Session.parseFromDictionary(any: $0) }
            .do(onSuccess: { session in
                SessionService.store(session: session)
                
                if session?.userToken != nil {
                    AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.accept(Void())
                }
            })
    }
}
