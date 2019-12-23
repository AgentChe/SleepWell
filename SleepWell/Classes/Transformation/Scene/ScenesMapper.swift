//
//  ScenesMapper.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 21/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

struct FullScenes {
    let scenes: [Scene]
    let details: [SceneDetail]
    let scenesHashCode: String
    let deletedSceneIds: [Int]
    let copingLocalImages: [CopyResource]
}

struct ScenesMapper {
    static func fullScenes(response: Any) -> FullScenes? {
        guard let json = response as? [String: Any], let data = json["_data"] as? [String: Any] else {
            return nil
        }
        
        let fullScenes = data["scenes"] as? [[String: Any]] ?? []
        
        var scenes: [Scene] = []
        var scenesDetails: [SceneDetail] = []
        var copingLocalImages: [CopyResource] = []
        
        for fullScene in fullScenes {
            guard let scene = Scene.parseFromDictionary(any: fullScene) else {
                continue
            }
            
            let soundsJSONArray = fullScene["sounds"] as? [[String: Any]] ?? []
            let sounds = soundsJSONArray.compactMap { SceneSound.parseFromDictionary(any: $0) }
            let details = SceneDetail(scene: scene, sounds: sounds)
            
            if scene.mime.isImage, let imageSceneLocalName = fullScene["image_path"] as? String {
                copingLocalImages.append(CopyResource(name: imageSceneLocalName, cacheKey: scene.url.absoluteString))
            }
            
            scenes.append(scene)
            scenesDetails.append(details)
        }
        
        let hashCode = data["scenes_hash"] as? String ?? ""
        
        let deletecSceneIds = data["deleted_scenes"] as? [Int] ?? []
        
        return FullScenes(scenes: scenes,
                          details: scenesDetails,
                          scenesHashCode: hashCode,
                          deletedSceneIds: deletecSceneIds,
                          copingLocalImages: copingLocalImages)
    }
}
