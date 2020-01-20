//
//  NoiseCategory.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

struct NoiseCategory: Model {
    let id: Int
    let name: String
    let noises: [Noise]
}

extension NoiseCategory {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case noises = "sounds"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        noises = try container.decode([Noise].self, forKey: .noises)
    }
}
