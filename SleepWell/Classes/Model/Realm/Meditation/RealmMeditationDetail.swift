//
//  RealmMeditationDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift
import Foundation

class RealmMeditationDetail: Object {
    @objc dynamic var id: Int = Int.random(in: Int.min...Int.max)
    @objc dynamic var recording: RealmMeditation!
    @objc dynamic var readingSound: RealmMeditationSound!
    @objc dynamic var ambientSound: RealmMeditationSound?
    
    convenience init(recording: Meditation,
                     readingSound: MeditationSound,
                     ambientSound: MeditationSound?) {
        self.init()
        
        id = recording.id
        
        self.recording = MeditationRealmMapper.map(from: recording)
        self.readingSound = MeditationSoundRealmMapper.map(from: readingSound)
        
        if let ambient = ambientSound {
            self.ambientSound = MeditationSoundRealmMapper.map(from: ambient)
        }
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
