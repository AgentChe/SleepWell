//
//  RealmStoryDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RealmSwift

class RealmStoryDetail: Object {
    @objc dynamic var id: Int = Int.random(in: Int.min...Int.max)
    @objc dynamic var recording: RealmStory!
    @objc dynamic var readingSound: RealmStorySound!
    @objc dynamic var ambientSound: RealmStorySound?
    
    convenience init(recording: Story,
                     readingSound: StorySound,
                     ambientSound: StorySound?) {
        self.init()
        
        id = recording.id
        
        self.recording = StoryRealmMapper.map(from: recording)
        self.readingSound = StorySoundRealmMapper.map(from: readingSound)
        
        if let ambient = ambientSound {
            self.ambientSound = StorySoundRealmMapper.map(from: ambient)
        }
    }
    
    @objc open override class func primaryKey() -> String? {
        return "id"
    }
}
