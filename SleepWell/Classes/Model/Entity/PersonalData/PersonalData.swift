//
//  PersonalData.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 12/06/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSError

struct PersonalData {
    let aims: [Aim]
    let gender: Gender
    let birthYear: Int
    let pushToken: String?
    let pushTime: String?
    let pushIsEnabled: Bool
}

// MARK: Make

extension PersonalData: Model {
    enum CodingKeys: CodingKey {
        case aims
        case gender
        case birthYear
        case pushToken
        case pushTime
        case pushIsEnabled
    }
    
    init(response: Any) throws {
        guard let json = response as? [String: Any],
            let data = json["_date"] as? [String: Any]
        else {
            throw NSError(domain: "Personal data parse: response invalidate", code: 404)
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
