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
    @objc dynamic var mimeValue: Int = -1
    @objc dynamic var sort: Int = 0
    
    convenience init(
        id: Int,
        paid: Bool,
        url: URL,
        hash: String,
        mimeValue: Int,
        sort: Int
    ) {
        self.init()
        
        self.id = id
        self.paid = paid
        self.url = url.absoluteString
        self.hashCode = hash
        self.mimeValue = mimeValue
        self.sort = sort 
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
