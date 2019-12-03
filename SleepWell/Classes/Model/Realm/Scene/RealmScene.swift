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
    @objc dynamic var imageUrl: String?
    @objc dynamic var hashCode: String = ""
    
    convenience init(id: Int,
                     paid: Bool,
                     imageUrl: URL?,
                     hash: String) {
        self.init()
        
        self.id = id
        self.paid = paid
        self.imageUrl = imageUrl?.absoluteString
        self.hashCode = hash
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
