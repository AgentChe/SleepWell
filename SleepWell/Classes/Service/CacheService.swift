//
//  CacheService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 03/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import Kingfisher

final class CacheService {
    private let cacheMeditations = CacheMeditations()
    private let cacheStories = CacheStories()
    private let updateScenes = UpdateScenes()
    
    func update() -> Single<Void> {
        return Observable
            .combineLatest(cacheMeditations.copyMeditations().catchErrorJustReturn(Void()),
                           cacheStories.copyStories().catchErrorJustReturn(Void()))
            .flatMap { [unowned self] _ -> Observable<Void> in
                return Observable
                    .combineLatest(self.cacheMeditations.updateMeditations().catchErrorJustReturn(Void()),
                                   self.cacheStories.update().catchErrorJustReturn(Void()),
                                   self.updateScenes.update().catchErrorJustReturn(Void()),
                                   self.cacheMeditations.updateTags().catchErrorJustReturn(Void())) { _, _, _, _ in Void() }
            }
            .asSingle()
    }
}

private protocol Copy {}
private extension Copy {
    func whatCopy<T>(resource: String, map: @escaping (Any) -> (T?)) -> Observable<T?> {
        Observable<T?>.create { observer in
            guard
                let url = Bundle.main.url(forResource: resource, withExtension: "json"),
                let jsonData = try? Data(contentsOf: url, options: .dataReadingMapped),
                let json = try? JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
            else {
                observer.onError(RxError.noElements)
                return Disposables.create()
            }
            
            let data = map(json)
            
            observer.onNext(data)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}

private final class CacheMeditations: Copy {
    private let downloadImagesService = DownloadImagesService()
    private let copyImagesService = CopyImagesService()
    
    func copyMeditations() -> Observable<Void> {
        let fullMeditations = whatCopy(resource: "meditations", map: { MeditationsMapper.fullMeditations(response: $0) })
        
        return fullMeditations
            .flatMap { fullMeditations -> Observable<Void> in
                guard let data = fullMeditations else {
                    return .error(RxError.noElements)
                }

                let saveMeditations = RealmDBTransport().saveData(entities: data.meditations, map: { MeditationRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! MeditationDetailRealmMapper.map(from: $0) })
                
                return Observable
                    .combineLatest(saveMeditations.asObservable(),
                                   saveDetails.asObservable())
                    .flatMap { [weak self] _ -> Single<Void> in
                        return self?.copyImagesService.copyImages(copingLocalImages: data.copingLocalImages) ?? .just(Void())
                    }
                    .do(onNext: {
                        CacheHashCodes.meditationsHashCode = data.meditationsHashCode
                    })
            }
    }
    
    func updateMeditations() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: FullMeditationsListRequest(hashCode: CacheHashCodes.meditationsHashCode))
            .asObservable()
            .map { MeditationsMapper.fullMeditations(response: $0) }
            .flatMap { fullMeditations -> Observable<Void> in
                guard let data = fullMeditations else {
                    return .error(RxError.noElements)
                }
                
                let saveMeditations = RealmDBTransport().saveData(entities: data.meditations, map: { MeditationRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! MeditationDetailRealmMapper.map(from: $0) })
                let removeMeditations = RealmDBTransport().deleteData(realmType: RealmMeditation.self, filter: NSPredicate(format: "id IN %@", data.deletedMeditationIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmMeditationDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedMeditationIds))
                
                return Observable
                    .combineLatest(saveMeditations.asObservable(),
                                   saveDetails.asObservable(),
                                   removeMeditations.asObservable(),
                                   removeDetails.asObservable()) { _, _, _, _ -> [URL] in
                        return data.meditations.reduce([]) { urls, meditation -> [URL] in
                            var result = urls
                            if let imagePreviewUrl = meditation.imagePreviewUrl { result.append(imagePreviewUrl) }
                            if let imageReaderURL = meditation.imageReaderURL { result.append(imageReaderURL) }
                            return result
                        }
                    }
                    .flatMap { [weak self] urls -> Single<Void> in self?.downloadImagesService.downloadImages(urls: urls) ?? .just(Void()) }
                    .do(onNext: {
                        CacheHashCodes.meditationsHashCode = data.meditationsHashCode
                    })
            }
    }
    
    func updateTags() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: MeditationTagsRequest(hashCode: CacheHashCodes.meditationTagsHashCode))
            .asObservable()
            .map { TagsMapper.parse(response: $0) }
            .flatMap { fullTags -> Observable<Void> in
                return RealmDBTransport()
                    .saveData(entities: fullTags.tags, map: { MeditationTagRealmMapper.map(from: $0) })
                    .do(onSuccess: {
                        CacheHashCodes.meditationTagsHashCode = fullTags.tagsHashCode
                    })
                    .asObservable()
            }
    }
}

private final class CacheStories: Copy {
    private let downloadImagesService = DownloadImagesService()
    private let copyImagesService = CopyImagesService()
    
    func copyStories() -> Observable<Void> {
        let fullStories = whatCopy(resource: "stories", map: { StoriesMapper.fullStories(response: $0) })
        
        return fullStories
            .flatMap { fullStories -> Observable<Void> in
                guard let data = fullStories else {
                    return .error(RxError.noElements)
                }

                let saveStories = RealmDBTransport().saveData(entities: data.stories, map: { StoryRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! StoryDetailRealmMapper.map(from: $0) })
                
                return Observable
                    .combineLatest(saveStories.asObservable(),
                                   saveDetails.asObservable())
                    .flatMap { [weak self] _ -> Single<Void> in
                        return self?.copyImagesService.copyImages(copingLocalImages: data.copingLocalImages) ?? .just(Void())
                    }
                    .do(onNext: {
                        CacheHashCodes.storiesHashCode = data.storiesHashCode
                    })
            }
    }
    
    func update() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: FullStoriesListRequest(hashCode: CacheHashCodes.storiesHashCode))
            .asObservable()
            .map { StoriesMapper.fullStories(response: $0) }
            .flatMap { fullStories -> Observable<Void> in
                guard let data = fullStories else {
                    return .error(RxError.noElements)
                }
                
                let saveStories = RealmDBTransport().saveData(entities: data.stories, map: { StoryRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! StoryDetailRealmMapper.map(from: $0) })
                let removeStories = RealmDBTransport().deleteData(realmType: RealmStory.self, filter: NSPredicate(format: "id IN %@", data.deletedStoryIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmStoryDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedStoryIds))
                
                return Observable
                    .combineLatest(saveStories.asObservable(),
                                   saveDetails.asObservable(),
                                   removeStories.asObservable(),
                                   removeDetails.asObservable()) { _, _, _, _ -> [URL] in
                        return data.stories.reduce([]) { urls, story -> [URL] in
                            var result = urls
                            if let imagePreviewUrl = story.imagePreviewUrl { result.append(imagePreviewUrl) }
                            if let imageReaderURL = story.imageReaderURL { result.append(imageReaderURL) }
                            return result
                        }
                    }
                    .flatMap { [weak self] urls -> Single<Void> in self?.downloadImagesService.downloadImages(urls: urls) ?? .just(Void()) }
                    .do(onNext: {
                        CacheHashCodes.storiesHashCode = data.storiesHashCode
                    })
            }
    }
}

private final class UpdateScenes: Copy {
    private let downloadImagesService = DownloadImagesService()
    private let copyImagesService = CopyImagesService()
    
    func update() -> Observable<Void> {
        return RestAPITransport()
            .callServerApi(requestBody: FullScenesListRequest(hashCode: CacheHashCodes.scenesHashCode))
            .asObservable()
            .map { ScenesMapper.fullScenes(response: $0) }
            .flatMap { fullScenes -> Observable<Void> in
                guard let data = fullScenes else {
                    return .error(RxError.noElements)
                }
                
                let saveScenes = RealmDBTransport().saveData(entities: data.scenes, map: { SceneRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { SceneDetailRealmMapper.map(from: $0) })
                let removeScenes = RealmDBTransport().deleteData(realmType: RealmScene.self, filter: NSPredicate(format: "id IN %@", data.deletedSceneIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmSceneDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedSceneIds))
                
                return Observable
                    .combineLatest(saveScenes.asObservable(),
                                   saveDetails.asObservable(),
                                   removeScenes.asObservable(),
                                   removeDetails.asObservable()) { _, _, _, _ -> [URL] in data.scenes.map { $0.url } }
                    .flatMap { [weak self] urls -> Single<Void> in self?.downloadImagesService.downloadImages(urls: urls) ?? .just(Void()) }
                    .do(onNext: {
                        CacheHashCodes.scenesHashCode = data.scenesHashCode
                    })
            }
    }
}

private final class CacheHashCodes {
    private static let meditationsHashCodeKey = "meditations_hash_code_key"
    private static let storiesHashCodeKey = "stories_hash_code_key"
    private static let scenesHashCodeKey = "scenes_hash_code_key"
    private static let meditationTagsHashCodeKey = "meditation_tags_hash_code_key"
    
    static var meditationsHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: meditationsHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: meditationsHashCodeKey)
        }
    }
    
    static var storiesHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: storiesHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: storiesHashCodeKey)
        }
    }
    
    static var scenesHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: scenesHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: scenesHashCodeKey)
        }
    }
    
    static var meditationTagsHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: meditationTagsHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: meditationTagsHashCodeKey)
        }
    }
}
