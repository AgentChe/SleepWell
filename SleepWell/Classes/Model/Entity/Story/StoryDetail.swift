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
    
    init(from decoder: Decoder) throws {
        recording = Story(id: 0,
                               name: "",
                               paid: false,
                               reader: "",
                               imagePreviewUrl: nil,
                               imageReaderURL: nil,
                               hash: "",
                               length_sec: 0)
        
        readingSound = StorySound(id: 0, soundUrl: URL(string: "www.google.com")!, soundSecs: 0)
        ambientSound = nil
    }

    func encode(to encoder: Encoder) throws {

    }
}
