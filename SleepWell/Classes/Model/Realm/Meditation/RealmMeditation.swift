//
//  RealmMeditation.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import RealmSwift

class RealmMeditation: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var paid: Bool = true
    @objc dynamic var reader: String?
    @objc dynamic var imagePreviewURL: String?
    @objc dynamic var imageReaderURL: String?
    @objc dynamic var meditationHash: String = ""
    let tags = List<Int>()
    @objc dynamic var length: Int = 0
    
    convenience init(id: Int,
                     name: String,
                     paid: Bool,
                     reader: String?,
                     imagePreviewURL: URL?,
                     imageReaderURL: URL?,
                     meditationHash: String,
                     tags: [Int],
                     length: Int) {
        self.init()

        self.id = id
        self.name = name
        self.paid = paid
        self.reader = reader
        self.imagePreviewURL = imagePreviewURL?.absoluteString
        self.imageReaderURL = imageReaderURL?.absoluteString
        self.meditationHash = meditationHash
        self.tags.append(objectsIn: tags)
        self.length = length
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }

}
