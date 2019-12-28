//
//  AttributionAPIService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import iAd
import RxSwift

final class AttributionAPIService {
    static let shared = AttributionAPIService()
    
    private let attributesWereSetKey = "attributes_were_set_key"
    
    private init() {}
    
    func configure() {
        setAttributionsApiWhenTokenUpdated()
    }
    
    private func setAttributionsApiWhenTokenUpdated() {
        _ = Observable
        .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
               AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .subscribe(onNext: {
                if let userId = SessionService.userId {
                    Analytics.shared.setUserId(userId: userId)
                }
                
                if UserDefaults.standard.bool(forKey: self.attributesWereSetKey) {
                    return
                }
                
                self.getAttributionDetails { details in
                    guard let dict = details else {
                        return
                    }
                    
                    Analytics.shared.setUserAttributes(attributes: dict)
                    
                    if dict["iad-attribution"] as? String == "true" {
                        Analytics.shared.log(with: .searcgAdsClickAd)
                    }
                    
                    UserDefaults.standard.set(true, forKey: self.attributesWereSetKey)
                }
            })
    }
    
    func getAttributionDetails(handler: @escaping ([String: NSObject]?) -> Void) {
        ADClient.shared().requestAttributionDetails { details, _ in
            handler(details?.first?.value as? [String: NSObject])
        }
    }
}

