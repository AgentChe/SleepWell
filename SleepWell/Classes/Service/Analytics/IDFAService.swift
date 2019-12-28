//
//  IDFAService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 27/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import AdSupport

final class IDFAService {
    static let shared = IDFAService()
    
    private let appRegisteredKey = "app_registered_key"
    
    private init() {}
    
    func configure() {
        appRegister()
        setIDFAWhenUserTokenUpdated()
        setAttributionsWhenUserTokenUpdated()
    }
    
    private func appRegister() {
        if UserDefaults.standard.bool(forKey: appRegisteredKey) {
            return
        }
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        let randomKey = getRandomKey()
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        AttributionAPIService.shared.getAttributionDetails { attributions in
            let request = AppRegisterRequest(idfa: idfa, randomKey: randomKey, version: version, attributions: attributions)
            
            _ = RestAPITransport().callServerApi(requestBody: request)
                .subscribe(onSuccess: { _ in
                    UserDefaults.standard.set(true, forKey: self.appRegisteredKey)
                })
        }
    }
    
    private func setIDFAWhenUserTokenUpdated() {
        _ = Observable
            .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
                   AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .flatMapLatest { _ -> Single<Any> in
                guard let userToken = SessionService.userToken else {
                    return .never()
                }

                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                let isAdvertisingTrackingEnabled = ASIdentifierManager.shared().isAdvertisingTrackingEnabled
                
                let request = SetRequest(userToken: userToken,
                                         locale: Locale.current.regionCode ?? "en",
                                         version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                                         timezone: TimeZone.current.identifier,
                                         idfa: idfa,
                                         isAdvertisingTrackingEnabled: isAdvertisingTrackingEnabled,
                                         randomKey: self.getRandomKey(),
                                         storeCountry: Locale.current.currencyCode ?? "")

                return RestAPITransport()
                    .callServerApi(requestBody: request)
                    .catchError { _ in .never() }
            }
            .subscribe()
    }
    
    private func setAttributionsWhenUserTokenUpdated() {
        _ = Observable
            .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
                   AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .flatMapLatest {
                return Observable<[String: NSObject]?>.create { observer in
                    AttributionAPIService.shared.getAttributionDetails { attributions in
                        observer.onNext(attributions)
                        observer.onCompleted()
                    }
                    
                    return Disposables.create()
                }
            }
            .flatMapLatest { attributions -> Single<Any> in
                guard let attr = attributions, let userToken = SessionService.userToken else {
                    return .never()
                }
            
                let request = AddSearchAdsInfoRequest(userToken: userToken, attributions: attr)
                
                return RestAPITransport()
                    .callServerApi(requestBody: request)
                    .catchError { _ in .never() }
                }
            .subscribe()
    }
    
    private func getRandomKey() -> String {
        let udKey = "app_random_key"
        
        if let randomKey = UserDefaults.standard.string(forKey: udKey) {
            return randomKey
        } else {
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let randomKey = String((0..<128).map{ _ in letters.randomElement()! })
            UserDefaults.standard.set(randomKey, forKey: udKey)
            return randomKey
        }
    }
}
