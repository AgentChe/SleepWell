//
//  RealmMeditationTag.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import RealmSwift

class RealmMeditationTag: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var meditationsCount: Int = 0
    
    convenience init(id: Int, name: String, meditationsCount: Int) {
        self.init()
        
        self.id = id
        self.name = name
        self.meditationsCount = meditationsCount
    }

    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
