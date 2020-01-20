//
//  Noise.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Noise: Model, Hashable {
    let id: Int
    let name: String
    let paid: Bool
    let noiseCategoryId: Int
    let imageUrl: URL
    let sounds: [NoiseSound]
    let hash: String
}

extension Noise {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case paid
        case noiseCategoryId = "sound_category_id"
        case imageUrl = "image_url"
        case sounds
        case hash = "sound_hash"
    }
    
    private enum Error: Swift.Error {
        case hasNotUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard
            let imageUrlString = try? container.decode(String?.self, forKey: .imageUrl)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: imageUrlString)
        else {
            throw Error.hasNotUrl
        }
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        paid = try container.decode(Bool.self, forKey: .paid)
        noiseCategoryId = try container.decode(Int.self, forKey: .noiseCategoryId)
        imageUrl = url
        sounds = try container.decode([NoiseSound].self, forKey: .sounds)
        hash = try container.decode(String.self, forKey: .hash)
    }
}
