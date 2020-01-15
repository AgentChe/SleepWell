//
//  NoiseSound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct NoiseSound: Sound, Hashable {
    let id: Int
    let soundUrl: URL
    let soundSecs: Int
}

extension NoiseSound {
    private enum CodingKeys: String, CodingKey {
        case id
        case soundUrl = "sound_url"
        case soundSecs = "sound_secs"
    }
    
    enum Error: Swift.Error {
        case invalidValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        
        let sound = try container.decode(String.self, forKey: .soundUrl)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let soundURL = URL(string: sound) else {
            throw Error.invalidValue
        }
        self.soundUrl = soundURL
        self.soundSecs = try container.decode(Int.self, forKey: .soundSecs)
    }
}
