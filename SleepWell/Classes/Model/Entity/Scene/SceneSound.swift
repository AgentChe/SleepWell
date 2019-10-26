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
}
