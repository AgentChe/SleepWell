//
//  Story.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct Story: Recording {
    let id: Int
    let name: String
    let paid: Bool
    let reader: String
    let imagePreviewUrl: URL?
    let imageReaderURL: URL?
    let hash: String
    let length_sec: Int
}
