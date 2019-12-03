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
        return RealmDBTransport()
            .loadData(realmType: RealmMeditation.self, map: { MeditationRealmMapper.map(from: $0) })
    }
    
    func getMeditation(meditationId: Int) -> Single<MeditationDetail?> {
        return RealmDBTransport()
            .loadData(realmType: RealmMeditationDetail.self, filter: NSPredicate(format: "recording.id == %i", meditationId), map: { MeditationDetailRealmMapper.map(from: $0) })
            .map { $0.first }
    }
    
    func getTags() -> Observable<[MeditationTag]> {
        let cacheTags = RealmDBTransport()
            .loadData(realmType: RealmMeditationTag.self) {
                MeditationTagRealmMapper.map(from: $0)
            }

        let request = MeditationTagsRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        
        let tags = RestAPITransport()
            .callServerApi(requestBody: request)
            .map { TagsMapper.parse(response: $0) }
            .flatMap { tags in
                RealmDBTransport()
                    .deleteData(realmType: RealmMeditationTag.self)
                    .flatMap { _ in
                        RealmDBTransport().saveData(entities: tags) {
                            MeditationTagRealmMapper.map(from: $0)
                        }
                    }
                
            }
            .flatMap {
                cacheTags
            }
            .catchError { _ in
                cacheTags
            }

        return Observable.concat(cacheTags.asObservable(), tags.asObservable())
    }
}
