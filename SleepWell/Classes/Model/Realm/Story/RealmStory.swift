//
//  RealmStory.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import RealmSwift

class RealmStory: Object {
   @objc dynamic var id: Int = 0
   @objc dynamic var name: String = ""
   @objc dynamic var paid: Bool = true
   @objc dynamic var reader: String = ""
   @objc dynamic var imagePreviewUrl: String?
   @objc dynamic var imageReaderURL: String?
   @objc dynamic var storyHash: String = ""
   @objc dynamic var length: Int = 0
    
    convenience init(id: Int,
                     name: String,
                     paid: Bool,
                     reader: String,
                     imagePreviewUrl: URL?,
                     imageReaderURL: URL?,
                     storyHash: String,
                     length: Int) {
        self.init()
    
        self.id = id
        self.name = name
        self.paid = paid
        self.reader = reader
        self.imagePreviewUrl = imagePreviewUrl?.absoluteString
        self.imageReaderURL = imageReaderURL?.absoluteString
        self.storyHash = storyHash
        self.length = length
    }

    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
