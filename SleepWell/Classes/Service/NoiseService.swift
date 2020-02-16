//
//  NoiseService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class NoiseService {
    func noiseCategories() -> Single<[NoiseCategory]> {
        return RealmDBTransport().loadData(realmType: RealmNoiseCategory.self, map: { NoiseCategoryRealmMapper.map(from: $0) })
    }
}
