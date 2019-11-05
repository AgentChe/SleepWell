//
//  MeditationCellModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct MeditationCellModel {
    let id: Int
    let image: URL?
    let name: String
    let avatar: URL?
    let reader: String
    let time: Int
    let paid: Bool
}

extension MeditationCellModel {
    init(story: Meditation, isActiveSubscription: Bool) {
        self.id = story.id
        self.image = story.imagePreviewUrl
        self.name = story.name
        self.avatar = story.imageReaderURL
        self.reader = story.reader
        self.time = story.length
        self.paid = isActiveSubscription ? true : !story.paid
    }
}
