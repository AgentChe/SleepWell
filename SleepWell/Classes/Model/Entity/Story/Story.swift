//
//  Story.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Story: Recording {
    let id: Int
    let name: String
    let paid: Bool
    let reader: String
    let imagePreviewUrl: URL?
    let imageReaderURL: URL?
    let hash: String
    let length: Int
}

extension Story {
    private enum DataKeys: String, CodingKey {
        case id
        case name
        case paid
        case reader
        case imagePreview = "image_story_url"
        case imageReader = "image_reader_url"
        case hash = "story_hash"
        case length = "length_secs"
    }
    
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: DataKeys.self)
        
        let readerImage = try data.decode(String?.self, forKey: .imageReader)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let preview = try data.decode(String?.self, forKey: .imagePreview)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        id = try data.decode(Int.self, forKey: .id)
        name = try data.decode(String.self, forKey: .name)
        paid = try data.decode(Bool.self, forKey: .paid)
        reader = try data.decode(String.self, forKey: .reader)
        imagePreviewUrl = URL(string: preview)
        imageReaderURL = URL(string: readerImage)
        hash = try data.decode(String.self, forKey: .hash)
        length = try data.decode(Int.self, forKey: .length)
    }

    func encode(to encoder: Encoder) throws {}
}
