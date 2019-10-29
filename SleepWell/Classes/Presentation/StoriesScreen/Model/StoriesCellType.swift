//
//  StoriesCellType.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

enum StoriesCellType {
    case story(Story)
    case premiumUnlock
}

extension StoriesCellType {
    static func map(items: [Story], isSubscription: Bool) -> [StoriesCellType] {
        var elements: [StoriesCellType] = items.map { .story($0) }
        if !isSubscription {
            elements.insert(.premiumUnlock, at: 1)
        }
        return elements
    }
}
