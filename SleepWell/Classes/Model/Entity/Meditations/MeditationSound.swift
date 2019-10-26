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
