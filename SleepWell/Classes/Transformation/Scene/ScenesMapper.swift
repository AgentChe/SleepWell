//
//  ScenesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct ScenesMapper {
    typealias FullScenes = (scenes: [Scene], details: [SceneDetail], scenesHashCode: String)
    
    static func fullScenes(response: Any) -> FullScenes? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any], let fullScenes = data["scenes"] as? [[String: Any]] else {
            return nil
        }
        
        var scenes: [Scene] = []
        var scenesDetails: [SceneDetail] = []
        
        for fullScene in fullScenes {
            guard let scene = Scene.parseFromDictionary(any: fullScene) else {
                continue
            }
            
            let soundsJSONArray = fullScene["sounds"] as? [[String: Any]] ?? []
            let sounds = soundsJSONArray.compactMap { SceneSound.parseFromDictionary(any: $0) }
            let details = SceneDetail(scene: scene, sounds: sounds)
            
            scenes.append(scene)
            scenesDetails.append(details)
        }
        
        let hashCode = data["scenes_hash"] as? String ?? ""
        
        return (scenes, scenesDetails, hashCode)
    }
}
