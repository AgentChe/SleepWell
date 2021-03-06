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
    }
    
    func getIDFA() -> String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    func isAdvertisingTrackingEnabled() -> Bool {
        ASIdentifierManager.shared().isAdvertisingTrackingEnabled
    }
    
    func getAppKey() -> String {
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
    
    private func appRegister() {
        if UserDefaults.standard.bool(forKey: appRegisteredKey) {
            return
        }

        let idfa = getIDFA()
        let randomKey = getAppKey()
        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        SearchAttributionsDetails.request { attributionsDetails in
            let request = AppRegisterRequest(idfa: idfa,
                                             randomKey: randomKey,
                                             version: version,
                                             attributions: attributionsDetails)

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
                
                let request = SetRequest(userToken: userToken,
                                         locale: UIDevice.deviceLanguageCode ?? "en",
                                         version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                                         timezone: TimeZone.current.identifier,
                                         idfa: self.getIDFA(),
                                         isAdvertisingTrackingEnabled: self.isAdvertisingTrackingEnabled(),
                                         randomKey: self.getAppKey(),
                                         storeCountry: Locale.current.currencyCode ?? "")

                return RestAPITransport()
                    .callServerApi(requestBody: request)
                    .catchError { _ in .never() }
            }
            .subscribe()
    }
}
