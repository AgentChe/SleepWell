//
//  SceneSound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct SceneSound: Sound {
    let id: Int
    let name: String
    let soundUrl: URL
    let soundSecs: Int
    let defaultVolume: Int
}

extension SceneSound {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case soundUrl = "sounds_url"
        case soundSecs = "sound_secs"
        case defaultVolume = "default_volume"
    }
    
    enum Error: Swift.Error {
        case invalidValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        let sound = try container.decode(String.self, forKey: .soundUrl)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let soundURL = URL(string: sound) else {
            throw Error.invalidValue
        }
        self.soundUrl = soundURL
        self.soundSecs = try container.decode(Int.self, forKey: .soundSecs)
        self.defaultVolume = try container.decode(Int.self, forKey: .defaultVolume)
    }
}
