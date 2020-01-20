//
//  RealmNoise.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmNoise: Object {
    @objc dynamic var id: Int = -1
    @objc dynamic var name: String = ""
    @objc dynamic var paid: Bool = false
    @objc dynamic var noiseCategoryId: Int = -1
    @objc dynamic var imageUrl: String = ""
    let sounds = List<RealmNoiseSound>()
    @objc dynamic var hashCode: String = ""
    
    convenience init(id: Int,
                     name: String,
                     paid: Bool,
                     noiseCategoryId: Int,
                     imageUrl: String,
                     sounds: [NoiseSound],
                     hashCode: String) {
        self.init()
        
        self.id = id
        self.name = name
        self.paid = paid
        self.noiseCategoryId = noiseCategoryId
        self.imageUrl = imageUrl
        self.sounds.append(objectsIn: sounds.map { NoiseSoundRealmMapper.map(from: $0) })
        self.hashCode = hashCode
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
