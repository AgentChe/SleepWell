//
//  Sound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

protocol Sound: Model {
    var id: Int { get }
    var soundUrl: URL { get }
    var soundSecs: Int { get }
}
