//
//  StoriesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct StoriesMapper {
    typealias FullStories = (stories: [Story], details: [StoryDetail], storiesHashCode: String, deletedStoryIds: [Int])
    
    static func fullStories(response: Any) -> FullStories? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullStories = data["stories"] as? [[String: Any]] ?? []
        
        var stories: [Story] = []
        var storiesDetails: [StoryDetail] = []
        
        for fullStory in fullStories {
            guard
                let story = Story.parseFromDictionary(any: fullStory),
                let readingSoundJSON = fullStory["reading_sound"] as? [String: Any],
                let readingSound = StorySound.parseFromDictionary(any: readingSoundJSON)
            else {
                continue
            }
            
            let ambientSoundJSON = fullStory["ambient_sound"] as? [String: Any] ?? [:]
            let ambientSound = StorySound.parseFromDictionary(any: ambientSoundJSON)
            
            let details = StoryDetail(recording: story, readingSound: readingSound, ambientSound: ambientSound)
            
            stories.append(story)
            storiesDetails.append(details)
        }
        
        let hashCode = data["stories_hash"] as? String ?? ""
        
        let deletedStoryIds = data["deleted_stories"] as? [Int] ?? []
        
        return (stories, storiesDetails, hashCode, deletedStoryIds)
    }
}
