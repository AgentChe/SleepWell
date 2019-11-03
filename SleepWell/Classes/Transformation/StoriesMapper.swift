//
//  StoriesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct StoriesMapper {
    static func parse(response: Any) -> [Story] {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let stories = data["stories"] as? [[String: Any]] else {
            return []
        }
        return Story.parseFromArray(any: stories)
    }
}
