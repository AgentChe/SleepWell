//
//  TagsMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct TagsMapper {
    static func parse(response: Any) -> [MeditationTag] {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let stories = data["tags"] as? [[String: Any]] else {
            return []
        }
        return MeditationTag.parseFromArray(any: stories)
    }
}
