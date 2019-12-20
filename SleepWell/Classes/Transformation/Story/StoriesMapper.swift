//
//  StoriesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct FullStories {
    let stories: [Story]
    let details: [StoryDetail]
    let storiesHashCode: String
    let deletedStoryIds: [Int]
    let copingLocalImages: [CopingLocalImage]
}

struct StoriesMapper {
    static func fullStories(response: Any) -> FullStories? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullStories = data["stories"] as? [[String: Any]] ?? []
        
        var stories: [Story] = []
        var storiesDetails: [StoryDetail] = []
        var copingLocalImages: [CopingLocalImage] = []
        
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
            
            if let imageReaderUrl = story.imageReaderURL, let imageReaderLocalName = fullStory["image_reader_path"] as? String {
                copingLocalImages.append(CopingLocalImage(imageName: imageReaderLocalName, imageCacheKey: imageReaderUrl.absoluteString))
            }
            
            if let imageStoryUrl = story.imagePreviewUrl, let imageStoryLocalName = fullStory["image_story_path"] as? String {
                copingLocalImages.append(CopingLocalImage(imageName: imageStoryLocalName, imageCacheKey: imageStoryUrl.absoluteString))
            }
            
            stories.append(story)
            storiesDetails.append(details)
        }
        
        let hashCode = data["stories_hash"] as? String ?? ""
        
        let deletedStoryIds = data["deleted_stories"] as? [Int] ?? []
        
        return FullStories(stories: stories,
                           details: storiesDetails,
                           storiesHashCode: hashCode,
                           deletedStoryIds: deletedStoryIds,
                           copingLocalImages: copingLocalImages)
    }
}
