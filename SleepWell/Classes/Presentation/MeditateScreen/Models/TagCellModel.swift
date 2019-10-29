//
//  TagCellModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct TagCellModel {
    let id: Int
    let name: String
    let isSelected: Bool
}

extension TagCellModel {
    static func map(items: [MeditationTag], selectedId: Int?) -> [TagCellModel] {
        guard let id = selectedId else {
            return items.enumerated().map { TagCellModel(id: $1.id, name: $1.name, isSelected: $0 == 0) }
        }
        return items.map { TagCellModel(id: $0.id, name: $0.name, isSelected: $0.id == id) }
    }
}
