//
//  SessionService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class SessionService {
    private static let cachedSessionKey = "session_service_cached_session_key"

    static var session: Session? {
        guard let data = UserDefaults.standard.data(forKey: cachedSessionKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(Session.self, from: data)
    }
    
    static func store(session: Session?) {
        guard let data = try? JSONEncoder().encode(session) else {
            return
        }
        
        UserDefaults.standard.set(data, forKey: cachedSessionKey)
    }
    
    func check(userToken: String) -> Single<Session?> {
        return SDKStorage.shared
            .restApiTransport
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
