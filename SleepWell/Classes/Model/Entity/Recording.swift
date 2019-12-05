//
//  Record.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

protocol Recording: Model {
    var id: Int { get }
    var name: String { get }
    var paid: Bool { get }
    var reader: String { get }
    var imagePreviewUrl: URL? { get }
    var imageReaderURL: URL? { get }
    var hash: String { get }
}
