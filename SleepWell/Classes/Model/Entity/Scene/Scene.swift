//
//  Scene.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Scene: Model {
    let id: Int
    let paid: Bool
    let imageUrl: URL?
    let hash: String
}
