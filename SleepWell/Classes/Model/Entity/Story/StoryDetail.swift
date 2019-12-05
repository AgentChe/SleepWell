//
//  StoryDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct StoryDetail: RecordingDetail {
    let recording: Recording
    let readingSound: Sound
    let ambientSound: Sound?
}

extension StoryDetail {
    private enum DataKeys: String, CodingKey {
        case data = "_data"
    }
    
    private enum StoryKeys: String, CodingKey {
        case recording = "story"
        case hash = "story_hash"
    }
    
    private enum CodingKeys: String, CodingKey {
        case readingSound = "reading_sound"
        case ambientSound = "ambient_sound"
        case id
        case name
        case paid
        case reader
        case imagePreview = "image_story_url"
        case imageReader = "image_reader_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DataKeys.self)
        let data = try container.nestedContainer(keyedBy: StoryKeys.self, forKey: .data)
        let story = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .recording)
        

        let preview = try story.decode(String?.self, forKey: .imagePreview)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let reader = try story.decode(String?.self, forKey: .imageReader)?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        readingSound = try story.decode(StorySound.self, forKey: .readingSound)
        ambientSound = try story.decode(StorySound?.self, forKey: .ambientSound)
        
        recording = Story(id: try story.decode(Int.self, forKey: .id),
                          name: try story.decode(String.self, forKey: .name),
                          paid: try story.decode(Bool.self, forKey: .paid),
                          reader: try story.decode(String.self, forKey: .reader),
                          imagePreviewUrl: URL(string: preview),
                          imageReaderURL: URL(string: reader),
                          hash: try data.decode(String.self, forKey: .hash),
                          length: readingSound.soundSecs)
        
    }

    func encode(to encoder: Encoder) throws {

    }
}
