//
//  MeditationsMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct MeditationsMapper {
    static func parse(response: Any) -> [Meditation] {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let stories = data["meditations"] as? [[String: Any]] else {
            return []
        }
        return Meditation.parseFromArray(any: stories)
    }
}
