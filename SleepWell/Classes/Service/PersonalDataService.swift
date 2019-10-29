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

struct PersonalData {
    let aims: [Aim]
    let gender: Gender
    let pushToken: String?
    let pushTime: String?
}

class PersonalDataService {
    private static let personalDataKey = "personal_data_key"
    
    func hasPersonalData() -> Bool {
        return UserDefaults.standard.string(forKey: PersonalDataService.personalDataKey) != nil
    }
    
    func sendPersonalData() -> Single<Void> {
        return .just(Void())
    }
}
