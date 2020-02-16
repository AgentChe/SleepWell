//
//  RealmNoiseCategory.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmNoiseCategory: Object {
    @objc dynamic var id: Int = -1
    @objc dynamic var name: String = ""
    @objc dynamic var sort: Int = 0
    let noises = List<RealmNoise>()
    
    convenience init(id: Int,
                     name: String,
                     sort: Int,
                     noises: [Noise]) {
        self.init()
        
        self.id = id
        self.name = name
        self.sort = sort
        self.noises.append(objectsIn: noises.map { NoiseRealmMapper.map(from: $0) })
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
