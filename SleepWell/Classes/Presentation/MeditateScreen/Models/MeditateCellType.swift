//
//  MeditateCellType.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 27/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

enum MeditateCellType {
    case meditate(MeditationCellModel)
    case premiumUnlock
}

extension MeditateCellType {
    static func map(items: [Meditation], isSubscription: Bool) -> [MeditateCellType] {
        var elements: [MeditateCellType] = items.map { .meditate(.init(story: $0, isActiveSubscription: isSubscription)) }
        if !isSubscription && elements.count >= 1 {
            elements.insert(.premiumUnlock, at: 1)
        }
        return elements
    }
}
