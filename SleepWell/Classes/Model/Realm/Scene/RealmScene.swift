//
//  SceneRealmMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmScene: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var paid: Bool = true
    @objc dynamic var url: String = ""
    @objc dynamic var hashCode: String = ""
    @objc dynamic var hasVideoType: Bool = false
    
    convenience init(
        id: Int,
        paid: Bool,
        url: URL,
        hash: String,
        hasVideoType: Bool
    ) {
        self.init()
        
        self.id = id
        self.paid = paid
        self.url = url.absoluteString
        self.hashCode = hash
        self.hasVideoType = hasVideoType
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
