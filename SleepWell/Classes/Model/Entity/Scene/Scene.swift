//
//  Scene.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Scene: Model {
    let id: Int
    let paid: Bool
    let imageUrl: URL?
    let hash: String
}

extension Scene {
    private enum CodingKeys: String, CodingKey {
        case id
        case paid
        case imageUrl = "image_url"
        case hash = "scene_hash"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let imageUrl = try container.decode(String?.self, forKey: .imageUrl)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        id = try container.decode(Int.self, forKey: .id)
        paid = try container.decode(Bool.self, forKey: .paid)
        self.imageUrl = URL(string: imageUrl)
        hash = try container.decode(String.self, forKey: .hash)
    }

    func encode(to encoder: Encoder) throws {}
}
