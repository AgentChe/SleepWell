//
//  RealmSceneSound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmSceneSound: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var soundUrl: String = ""
    @objc dynamic var soundSecs: Int = 0
    
    convenience init(id: Int,
                     name: String,
                     soundUrl: URL,
                     soundSecs: Int) {
        self.init()
        
        self.id = id
        self.name = name
        self.soundUrl = soundUrl.absoluteString
        self.soundSecs = soundSecs
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
