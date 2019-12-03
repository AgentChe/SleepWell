//
//  TagsMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct TagsMapper {
    typealias FullTags = (tags: [MeditationTag], tagsHashCode: String)
    
    static func parse(response: Any) -> FullTags {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let stories = data["tags"] as? [[String: Any]] else {
            return ([], "")
        }
        
        let tags = MeditationTag.parseFromArray(any: stories)
        let tagsHachCode = data["tags_hash"] as? String ?? ""
        
        return (tags, tagsHachCode)
    }
}
