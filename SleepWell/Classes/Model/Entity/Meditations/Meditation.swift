//
//  Meditation.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Meditation: Recording {
    let id: Int
    let name: String
    let paid: Bool
    let reader: String
    let imagePreviewUrl: URL?
    let imageReaderURL: URL?
    let hash: String
    let tags: [Int]
    let length: Int
}

extension Meditation {
    private enum DataKeys: String, CodingKey {
        case id
        case name
        case paid
        case reader
        case imagePreviewUrl = "image_meditation_url"
        case imageReaderURL = "image_reader_url"
        case hash = "meditation_hash"
        case tags
        case length = "length_secs"
    }
    
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: DataKeys.self)
        
        let readerImage = try data.decode(String?.self, forKey: .imageReaderURL)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let preview = try data.decode(String?.self, forKey: .imagePreviewUrl)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        id = try data.decode(Int.self, forKey: .id)
        name = try data.decode(String.self, forKey: .name)
        paid = try data.decode(Bool.self, forKey: .paid)
        reader = try data.decode(String.self, forKey: .reader)
        imagePreviewUrl = URL(string: preview)
        imageReaderURL = URL(string: readerImage)
        hash = try data.decode(String.self, forKey: .hash)
        tags = try data.decode([Int].self, forKey: .tags)
        length = try data.decode(Int.self, forKey: .length)
    }
}
