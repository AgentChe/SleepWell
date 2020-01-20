//
//  NoiseMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

struct FullNoises {
    let noiseCategories: [NoiseCategory]
    let deletedNoiseCategoryIds: [Int]
    let deletedNoiseIds: [Int]
    let noisesHashCode: String
    let copingLocalImages: [CopyResource]
}

final class NoiseMapper {
    static func fullNoises(response: Any) -> FullNoises? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullNoises = data["sound_categories"] as? [[String: Any]] ?? []
        let deletedNoiseIds = data["deleted_sound_ids"] as? [Int] ?? []
        let deletedNoiseCategoryIds = data["deleted_sound_categories_ids"] as? [Int] ?? []
        let noisesHashCode = data["sound_categories_hash"] as? String ?? ""
        
        var categories: [NoiseCategory] = []
        var copingLocalImages: [CopyResource] = []
        
        for fullNoise in fullNoises {
            guard let noiseCategory = NoiseCategory.parseFromDictionary(any: fullNoise) else {
                continue
            }
            
            let sounds = fullNoise["sounds"] as? [[String: Any]] ?? []
            
            for sound in sounds {
                if let imageUrl = sound["image_url"] as? String, let imagePath = sound["image_path"] as? String {
                    copingLocalImages.append(CopyResource(name: imagePath, cacheKey: imageUrl))
                }
            }
            
            categories.append(noiseCategory)
        }
        
        return FullNoises(noiseCategories: categories,
                          deletedNoiseCategoryIds: deletedNoiseCategoryIds,
                          deletedNoiseIds: deletedNoiseIds,
                          noisesHashCode: noisesHashCode,
                          copingLocalImages: copingLocalImages)
    }
}
