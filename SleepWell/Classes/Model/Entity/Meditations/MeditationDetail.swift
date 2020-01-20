//
//  MeditationDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct MeditationDetail: RecordingDetail {
    let recording: Recording
    let readingSound: Sound
    let ambientSound: Sound?
}

extension MeditationDetail {
    private enum DataKeys: String, CodingKey {
           case data = "_data"
       }
       
    private enum MeditationKeys: String, CodingKey {
        case recording = "meditation"
        case hash = "meditation_hash"
    }
    
    private enum CodingKeys: String, CodingKey {
        case readingSound = "reading_sound"
        case ambientSound = "ambient_sound"
        case id
        case name
        case paid
        case reader
        case imagePreview = "image_meditation_url"
        case imageReader = "image_reader_url"
        case tags
        case sort
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DataKeys.self)
        let data = try container.nestedContainer(keyedBy: MeditationKeys.self, forKey: .data)
        let meditation = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .recording)
        
        let preview = try meditation.decode(String?.self, forKey: .imagePreview)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let reader = try meditation.decode(String?.self, forKey: .imageReader)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        readingSound = try meditation.decode(MeditationSound.self, forKey: .readingSound)
        ambientSound = try meditation.decode(MeditationSound?.self, forKey: .ambientSound)
        
        recording = Meditation(id: try meditation.decode(Int.self, forKey: .id),
                          name: try meditation.decode(String.self, forKey: .name),
                          paid: try meditation.decode(Bool.self, forKey: .paid),
                          reader: try meditation.decode(String.self, forKey: .reader),
                          imagePreviewUrl: URL(string: preview),
                          imageReaderURL: URL(string: reader),
                          hash: try data.decode(String.self, forKey: .hash),
                          tags: try meditation.decode([Int].self, forKey: .tags),
                          length: readingSound.soundSecs,
                          sort: try meditation.decode(Int.self, forKey: .sort))
    }
    
    func encode(to encoder: Encoder) throws {

    }
}
