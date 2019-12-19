//
//  MeditationsMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct MeditationsMapper {
    typealias FullMeditations = (meditations: [Meditation], details: [MeditationDetail], meditationsHashCode: String, deletedMeditationIds: [Int])
    
    static func fullMeditations(response: Any) -> FullMeditations? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullMeditations = data["meditations"] as? [[String: Any]] ?? []
        
        var meditations: [Meditation] = []
        var meditationDetails: [MeditationDetail] = []
        
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
            
            meditations.append(meditation)
            meditationDetails.append(details)
        }
        
        let hashCode = data["meditations_hash"] as? String ?? ""
        
        let deletedMeditationIds = data["deleted_meditations"] as? [Int] ?? []
        
        return (meditations, meditationDetails, hashCode, deletedMeditationIds)
    }
}
