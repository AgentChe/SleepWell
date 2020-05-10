//
//  SceneCellModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

enum SceneCellModel {
    case image(SceneCellModelFields)
    case video(SceneCellModelFields)
    
    var fields: SceneCellModelFields {
        switch self {
        case .image(let fields):
            return fields
        case .video(let fields):
            return fields
        }
    }
}

struct SceneCellModelFields {
    let id: Int
    let url: URL
    let paid: Bool
    let placeholderUrl: String
}

extension SceneCellModel {
    init(scene: Scene, isActiveSubscription: Bool) {
        let sceneCellModelFields = SceneCellModelFields(
            id: scene.id,
            url: scene.url,
            paid: isActiveSubscription ? true : !scene.paid,
            placeholderUrl: scene.placeholderUrl
        )
        self = scene.mime.isVideo
            ? .video(sceneCellModelFields)
            : .image(sceneCellModelFields)
    }

    static func map(scene: [Scene], isActiveSubscription: Bool) -> [SceneCellModel] {
        return scene.map {
            SceneCellModel(scene: $0, isActiveSubscription: isActiveSubscription)
        }
    }
}
