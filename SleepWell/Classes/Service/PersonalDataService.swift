//
//  PersonalDataService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

enum Aim: Int {
    case betterSleep = 1
    case increaseHappiness = 2
    case morningEasier = 3
    case reduceStress = 4
    case manageTinnitus = 5
    case buildSelfEstreem = 6
}

enum Gender: Int {
    case male = 1
    case female = 2
    case other = 3
}

struct PersonalData: Model {
    let aims: [Aim]
    let gender: Gender
    let birthYear: Int 
    let pushToken: String?
    let pushTime: String?
    let pushIsEnabled: Bool
    
    enum CodingKeys: CodingKey {
        case aims
        case gender
        case birthYear
        case pushToken
        case pushTime
        case pushIsEnabled
    }
    
    init(aims: [Aim],
         gender: Gender,
         birthYear: Int,
         pushToken: String?,
         pushTime: String?,
         pushIsEnabled: Bool) {
        self.aims = aims
        self.gender = gender
        self.birthYear = birthYear
        self.pushToken = pushToken
        self.pushTime = pushTime
        self.pushIsEnabled = pushIsEnabled
    }
    
    init(response: Any) throws {
        guard let json = response as? [String: Any],
            let data = response as? [String: Any]
        else {
            throw RxError.noElements
        }
        
        aims = (data["aims"] as? [Int] ?? []).compactMap { Aim(rawValue: $0) }
        gender = .other
        birthYear = 1992
        pushToken = nil
        pushTime = data["push_time"] as? String
        pushIsEnabled = data["push_notifications"] as? Bool ?? false
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let aimsInt = try container.decode([Int].self, forKey: .aims)
        aims = aimsInt.compactMap { Aim(rawValue: $0) }
        
        let genderInt = try container.decode(Int.self, forKey: .gender)
        gender = Gender(rawValue: genderInt) ?? .other
        
        birthYear = try container.decode(Int.self, forKey: .birthYear)
        pushToken = try container.decode(String?.self, forKey: .pushToken)
        pushTime = try container.decode(String?.self, forKey: .pushTime)
        pushIsEnabled = try container.decode(Bool.self, forKey: .pushIsEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(aims.map { $0.rawValue }, forKey: .aims)
        try container.encode(gender.rawValue, forKey: .gender)
        try container.encode(birthYear, forKey: .birthYear)
        try container.encode(pushToken, forKey: .pushToken)
        try container.encode(pushTime, forKey: .pushTime)
        try container.encode(pushIsEnabled, forKey: .pushIsEnabled)
    }
}

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
    
    func sendPersonalData() -> Single<Void> {
        guard
            let data = UserDefaults.standard.data(forKey: PersonalDataService.personalDataKey),
            let personalData = try? JSONDecoder().decode(PersonalData.self, from: data)
        else {
            return .error(RxError.noElements)
        }
        
        guard let userToken = SessionService.userToken else {
            return .error(RxError.noElements)
        }
        
        return RestAPITransport()
            .callServerApi(requestBody: SetRequest(userToken: userToken,
                                                   personalData: personalData,
                                                   locale: Locale.current.languageCode,
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
        guard let userToken = SessionService.userToken else {
            return .just(nil)
        }
        
        let request = GetPersonalDataRequest(userToken: userToken)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { try? PersonalData(response: $0) }
    }
}
