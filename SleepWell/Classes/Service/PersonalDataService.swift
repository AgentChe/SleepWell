//
//  PersonalDataService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class PersonalDataService {
    private static let personalDataKey = "personal_data_key"
    
    func hasPersonalData() -> Bool {
        guard
            let data = UserDefaults.standard.data(forKey: PersonalDataService.personalDataKey),
            let _ = try? JSONDecoder().decode(PersonalData.self, from: data)
         else {
            return false
        }
        
        return true
    }
}

// MARK: Store

extension PersonalDataService {
    func sendPersonalData() -> Single<Void> {
        guard
            let data = UserDefaults.standard.data(forKey: PersonalDataService.personalDataKey),
            let personalData = try? JSONDecoder().decode(PersonalData.self, from: data)
        else {
            return .error(RxError.noElements)
        }
        
        guard let userToken = SessionService.session?.userToken else {
            return .error(RxError.noElements)
        }
        
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: SetRequest(userToken: userToken,
                                                   personalData: personalData,
                                                   locale: UIDevice.deviceLanguageCode,
                                                   version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
                                                   timezone: TimeZone.current.identifier))
            .flatMap { response -> Single<Void> in
                let isError = try CheckResponseForCodeError.isError(jsonResponse: response)
                return isError ? .error(RxError.unknown) : .just(Void())
            }
        
    }
    
    func store(personalData: PersonalData) -> Single<Void> {
        return Single<Void>.create { single in
            let data = try? PersonalData.encode(object: personalData)
            
            UserDefaults.standard.set(data, forKey: PersonalDataService.personalDataKey)
            
            single(.success(Void()))
            
            return Disposables.create()
        }
    }
}

// MARK: Retrieve

extension PersonalDataService {
    static func cachedPersonalData() -> PersonalData? {
         guard
            let data = UserDefaults.standard.data(forKey: PersonalDataService.personalDataKey),
            let personalData = try? JSONDecoder().decode(PersonalData.self, from: data)
         else {
            return nil
        }

        return personalData
    }
    
    static func downloadPersonalData() -> Single<PersonalData?> {
        guard let userToken = SessionService.session?.userToken else {
            return .just(nil)
        }
        
        let request = GetPersonalDataRequest(userToken: userToken)
        
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: request)
            .map { try? PersonalData(response: $0) }
    }
    
    static func retrievePersonalData() -> Single<PersonalData?> {
        if let cached = cachedPersonalData() {
            return .deferred { .just(cached) }
        }
        
        return downloadPersonalData()
    }
}

// MARK: Anonymous

extension PersonalDataService {
    static func create() -> Single<Bool> {
        guard let personalData = cachedPersonalData() else {
            return .deferred { .just(false) }
        }
        
        return create(anonymous: personalData)
    }
    
    static func create(anonymous: PersonalData) -> Single<Bool> {
        guard let pushToken = anonymous.pushToken else {
            return .deferred { .just(false) }
        }
        
        let request = CreateAnonymousRequest(gender: anonymous.gender.rawValue,
                                             pushToken: pushToken,
                                             locale: UIDevice.deviceLanguageCode ?? "en",
                                             version: UIDevice.appVersion ?? "1",
                                             appKey: SDKStorage.shared.applicationAnonymousID)
        
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: request)
            .map { try CheckResponseForCodeError.isError(jsonResponse: $0) }
            .map { !$0 }
    }
}
