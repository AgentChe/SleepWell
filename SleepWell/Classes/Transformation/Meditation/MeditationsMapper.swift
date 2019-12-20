//
//  MeditationsMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct FullMeditations {
    let meditations: [Meditation]
    let details: [MeditationDetail]
    let meditationsHashCode: String
    let deletedMeditationIds: [Int]
    let copingLocalImages: [CopingLocalImage]
}

struct MeditationsMapper {
    static func fullMeditations(response: Any) -> FullMeditations? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullMeditations = data["meditations"] as? [[String: Any]] ?? []
        
        var meditations: [Meditation] = []
        var meditationDetails: [MeditationDetail] = []
        var copingLocalImages: [CopingLocalImage] = []
        
        for fullMeditation in fullMeditations {
            guard
                let meditation = Meditation.parseFromDictionary(any: fullMeditation),
                let readingSoundJSON = fullMeditation["reading_sound"] as? [String: Any],
                let readingSound = MeditationSound.parseFromDictionary(any: readingSoundJSON)
            else {
                continue
            }
            
            let ambientSoundJSON = fullMeditation["ambient_sound"] as? [String: Any] ?? [:]
            let ambientSound = MeditationSound.parseFromDictionary(any: ambientSoundJSON)
            
            let details = MeditationDetail(recording: meditation, readingSound: readingSound, ambientSound: ambientSound)
            
            if let imageReaderUrl = meditation.imageReaderURL, let imageReaderLocalName = fullMeditation["image_reader_path"] as? String {
                copingLocalImages.append(CopingLocalImage(imageName: imageReaderLocalName, imageCacheKey: imageReaderUrl.absoluteString))
            }
            
            if let imageMeditationUrl = meditation.imagePreviewUrl, let imageMeditationLocalName = fullMeditation["image_meditation_path"] as? String {
                copingLocalImages.append(CopingLocalImage(imageName: imageMeditationLocalName, imageCacheKey: imageMeditationUrl.absoluteString))
            }
            
            meditations.append(meditation)
            meditationDetails.append(details)
        }
        
        let hashCode = data["meditations_hash"] as? String ?? ""
        
        let deletedMeditationIds = data["deleted_meditations"] as? [Int] ?? []
        
        return FullMeditations(meditations: meditations,
                               details: meditationDetails,
                               meditationsHashCode: hashCode,
                               deletedMeditationIds: deletedMeditationIds,
                               copingLocalImages: copingLocalImages)
    }
}
