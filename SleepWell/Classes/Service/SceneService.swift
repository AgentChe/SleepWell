//
//  SceneService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class SceneService {
    func scenes() -> Single<[Scene]> {
        return RealmDBTransport().loadData(realmType: RealmScene.self, map: { SceneRealmMapper.map(from: $0) })
            .do(onSuccess: { scenes in
                print()
            })
    }
    
    func scene(by id: Int) -> Single<SceneDetail?> {
        return RealmDBTransport()
            .loadData(realmType: RealmSceneDetail.self, filter: NSPredicate(format: "id == %i", id), map: { SceneDetailRealmMapper.map(from: $0) })
            .map { $0.first }
    }
}
