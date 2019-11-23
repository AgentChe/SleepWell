//
//  MeditationService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class MeditationService {
    func meditations() -> Observable<[Meditation]> {
        let catchMeditations = RealmDBTransport()
            .loadData(realmType: RealmMeditation.self) {
                MeditationRealmMapper.map(from: $0)
            }

        let request = MeditationsListRequest(userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)

        let meditations = RestAPITransport()
            .callServerApi(requestBody: request)
            .map { MeditationsMapper.parse(response: $0) }
            .flatMap { meditations in
                RealmDBTransport()
                    .deleteData(realmType: RealmMeditation.self)
                    .flatMap { _ in
                        RealmDBTransport().saveData(entities: meditations) {
                        MeditationRealmMapper.map(from: $0)}
                    }
                
            }
            .flatMap {
                catchMeditations
            }
            .catchError { _ in
                catchMeditations
            }

        return Observable.concat(catchMeditations.asObservable(), meditations.asObservable())
    }
    
    func getMeditation(meditationId: Int) -> Single<MeditationDetail?> {
        let request = MeditationDetailRequest(meditationId: meditationId, userToken: SessionService.userToken, apiKey: GlobalDefinitions.apiKey)
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { MeditationDetail.parseFromDictionary(any: $0) }
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
