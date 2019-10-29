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
    
    init(from decoder: Decoder) throws {
        recording = Meditation(id: 0,
                               name: "",
                               paid: false,
                               reader: "",
                               imagePreviewUrl: nil,
                               imageReaderURL: nil,
                               hash: "",
                               tags: [])
        
        readingSound = MeditationSound(id: 0, soundUrl: URL(string: "www.google.com")!, soundSecs: 0)
        ambientSound = nil
    }
    
    init() {
        self.recording = Meditation(
            id: 0,
            name: "test meditation",
            paid: false,
            reader: "Dron",
            imagePreviewUrl: URL(
                string: "http://www.blackberryrc.com/uploads/allimg/160411/2-1604111FQ6-lp.jpg"
            )!,
            imageReaderURL: nil,
            hash: "",
            tags: []
        )
        let path = Bundle.main.path(forResource: "testSound", ofType: "mp3")!
        self.readingSound = MeditationSound(id: 0, soundUrl: URL(string: path)!, soundSecs: 0)
        
        self.ambientSound = nil
    }

    func encode(to encoder: Encoder) throws {

    }
}
