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
    let url: URL
    let hash: String
    let mime: Mime
}

extension Scene {
    
    private enum CodingKeys: String, CodingKey {
        case id
        case paid
        case mime
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case hash = "scene_hash"
    }
    
    private enum Error: Swift.Error {
        case unsupportedType
        case hasNotUrl
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let mimeValue = try container.decode(Int.self, forKey: .mime)
        guard let mime = Mime(rawValue: mimeValue) else {
            throw Error.unsupportedType
        }
        
        let imageUrlString = try? container.decode(String?.self, forKey: .imageUrl)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let videoUrlString = try? container.decode(String?.self, forKey: .videoUrl)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let videoUrl = URL(string: videoUrlString ?? ""), mime.isVideo {
            self.url = videoUrl
        } else if let imageUrl = URL(string: imageUrlString ?? ""), mime.isImage {
            self.url = imageUrl
        } else {
            throw Error.hasNotUrl
        }
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.paid = false//try container.decode(Bool.self, forKey: .paid)
        self.hash = try container.decode(String.self, forKey: .hash)
        self.mime = mime 
    }

    func encode(to encoder: Encoder) throws {}
}
