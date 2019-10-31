//
//  StoriesCellType.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

enum StoriesCellType {
    case story(StoryCellModel)
    case premiumUnlock
}

extension StoriesCellType {
    static func map(items: [Story], isSubscription: Bool) -> [StoriesCellType] {
        var elements: [StoriesCellType] = items.map { .story(.init(story: $0, isActiveSubscription: isSubscription)) }
        if !isSubscription && elements.count >= 1 {
            elements.insert(.premiumUnlock, at: 1)
        }
        return elements
    }
}
