//
//  SceneCellModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct SceneCellModel {
    let id: Int
    let image: URL?
    let paid: Bool
}

extension SceneCellModel {
    init(scene: Scene, isActiveSubscription: Bool) {
        id = scene.id
        image = scene.imageUrl
        paid = isActiveSubscription ? true : !scene.paid
    }

    static func map(scene: [Scene], isActiveSubscription: Bool) -> [SceneCellModel] {
        return scene.map {
            SceneCellModel(scene: $0, isActiveSubscription: isActiveSubscription)
        }
    }
}
