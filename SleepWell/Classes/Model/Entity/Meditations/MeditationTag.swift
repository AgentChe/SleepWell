//
//  MeditationTag.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

struct MeditationTag: Model {
    let id: Int
    let name: String
    let meditationsCount: Int
}

extension MeditationTag {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case meditationsCount = "meditations_count"
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        meditationsCount = try container.decode(Int.self, forKey: .meditationsCount)
    }
}
