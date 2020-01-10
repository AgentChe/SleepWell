//
//  GroupModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

struct GroupModel {
    let name: String
    let sounds: [SoundModel]
}

struct SoundModel {
    let id: Int
    let name: String
    let image: String
    let positionX: CGFloat
    let positionY: CGFloat
}
