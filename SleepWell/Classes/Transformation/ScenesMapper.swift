//
//  ScenesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct ScenesMapper {
    static func parse(response: Any) -> [Scene] {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let stories = data["scenes"] as? [[String: Any]] else {
            return []
        }
        return Scene.parseFromArray(any: stories)
    }
}
