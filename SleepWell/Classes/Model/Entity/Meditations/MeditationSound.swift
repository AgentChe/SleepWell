//
//  MeditationSound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct MeditationSound: Sound {
    let id: Int
    let soundUrl: URL
    let soundSecs: Int
}

extension MeditationSound {
    private enum CodingKeys: String, CodingKey {
        case id
        case soundUrl = "sound_url"
        case soundSecs = "sound_secs"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        
        let sound = try container.decode(String.self, forKey: .soundUrl).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        id = try container.decode(Int.self, forKey: .id)
        soundUrl = URL(string: sound)!
        soundSecs = try container.decode(Int.self, forKey: .soundSecs)
    }
}
