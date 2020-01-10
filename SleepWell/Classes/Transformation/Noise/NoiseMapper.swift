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
        let noisesHashCode = data["sound_categories_hash"] as? String ?? ""
        
        let categories = NoiseCategory.parseFromArray(any: fullNoises)
        
        return FullNoises(noiseCategories: categories,
                          deletedNoiseCategoryIds: [],
                          deletedNoiseIds: [],
                          noisesHashCode: noisesHashCode,
                          copingLocalImages: [])
    }
}
