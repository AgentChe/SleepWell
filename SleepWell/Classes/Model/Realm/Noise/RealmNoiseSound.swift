//
//  RealmNoiseSound.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmNoiseSound: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var soundUrl: String = ""
    @objc dynamic var soundSecs: Int = 0
    
    convenience init(id: Int,
                     soundUrl: URL,
                     soundSecs: Int) {
        self.init()
        
        self.id = id
        self.soundUrl = soundUrl.absoluteString
        self.soundSecs = soundSecs
    }
       
   @objc open override class func primaryKey() -> String? {
       return "id"
   }
}
