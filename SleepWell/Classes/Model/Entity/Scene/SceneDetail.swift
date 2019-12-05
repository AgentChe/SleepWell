//
//  SceneDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct SceneDetail: Model {
    let scene: Scene
    let sounds: [SceneSound]
}

extension SceneDetail {
    
    private enum DataKeys: String, CodingKey {
        case data = "_data"
    }
    
    enum SceneKeys: String, CodingKey {
        case scene = "scene"
        case hash = "scene_hash"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case paid
        case image = "image_url"
        case sounds
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DataKeys.self)
        let data = try container.nestedContainer(keyedBy: SceneKeys.self, forKey: .data)
        let scene = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .scene)
        
        let image = try scene.decode(String.self, forKey: .image)
        
        self.scene = Scene(
            id: try scene.decode(Int.self, forKey: .id),
            paid: try scene.decode(Bool.self, forKey: .paid),
            imageUrl: URL(string: image),
            hash: try data.decode(String.self, forKey: .hash)
        )
        
        self.sounds = try scene.decode([SceneSound].self, forKey: .sounds)
    }
    
    func encode(to encoder: Encoder) throws {

    }
}
