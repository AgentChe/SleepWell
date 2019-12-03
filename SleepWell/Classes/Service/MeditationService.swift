//
//  MeditationService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class MeditationService {
    func meditations() -> Single<[Meditation]> {
        return RealmDBTransport().loadData(realmType: RealmMeditation.self, map: { MeditationRealmMapper.map(from: $0) })
    }
    
    func meditation(meditationId: Int) -> Single<MeditationDetail?> {
        return RealmDBTransport()
            .loadData(realmType: RealmMeditationDetail.self, filter: NSPredicate(format: "id == %i", meditationId), map: { MeditationDetailRealmMapper.map(from: $0) })
            .map { $0.first }
    }
    
    func tags() -> Single<[MeditationTag]> {
        return RealmDBTransport()
            .loadData(realmType: RealmMeditationTag.self, filter: NSPredicate(format: "meditationsCount > %i", 0), map: { MeditationTagRealmMapper.map(from: $0) })
    }
}
