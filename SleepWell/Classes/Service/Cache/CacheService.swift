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
    private let cacheScenes = CacheScenes()
    private let cacheNoise = CacheNoise()
    
    func update() -> Single<Void> {
        return Observable
            .combineLatest(cacheMeditations.copyMeditations().catchErrorJustReturn(Void()),
                           cacheStories.copyStories().catchErrorJustReturn(Void()),
                           cacheScenes.copyScenes().catchErrorJustReturn(Void()),
                           cacheNoise.copyNoises().catchErrorJustReturn(Void()))
            .flatMap { [unowned self] _ -> Observable<Void> in
                return Observable
                    .combineLatest(self.cacheMeditations.updateMeditations().catchErrorJustReturn(Void()),
                                   self.cacheStories.update().catchErrorJustReturn(Void()),
                                   self.cacheScenes.update().catchErrorJustReturn(Void()),
                                   self.cacheMeditations.updateTags().catchErrorJustReturn(Void()),
                                   self.cacheNoise.update().catchErrorJustReturn(Void())) { _, _, _, _, _ in Void() }
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
    
    var wasCopied: Bool {
        set { UserDefaults.standard.set(true, forKey: "meditations_was_copied_in_db_key_v2") }
        get { return UserDefaults.standard.bool(forKey: "meditations_was_copied_in_db_key_v2") }
    }
    
    func copyMeditations() -> Observable<Void> {
        guard !wasCopied else {
            return Observable<Void>.just(Void())
        }
        
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
                    .map { _ in Void() }
                    .do(onNext: { [weak self] in
                        self?.copyImagesService.backgroundCopyImages(copingLocalImages: data.copingLocalImages)
                        self?.wasCopied = true
                        CacheHashCodes.meditationsHashCode = data.meditationsHashCode
                    })
            }
    }
    
    func updateMeditations() -> Observable<Void> {
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: FullMeditationsListRequest(hashCode: CacheHashCodes.meditationsHashCode))
            .asObservable()
            .map { MeditationsMapper.fullMeditations(response: $0) }
            .flatMap { fullMeditations -> Observable<Void> in
                guard let data = fullMeditations else {
                    return .error(RxError.noElements)
                }
                
                let oldMeditations = RealmDBTransport().loadData(
                    realmType: RealmMeditationDetail.self,
                    map: MeditationDetailRealmMapper.map
                )
                let saveMeditations = RealmDBTransport().saveData(entities: data.meditations, map: { MeditationRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! MeditationDetailRealmMapper.map(from: $0) })
                let removeMeditations = RealmDBTransport().deleteData(realmType: RealmMeditation.self, filter: NSPredicate(format: "id IN %@", data.deletedMeditationIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmMeditationDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedMeditationIds))
                
                return oldMeditations.asObservable()
                    .catchErrorJustReturn([])
                    .map { meditations -> [URL] in
                        let oldArchivedMeditationsIds = meditations.compactMap {
                            $0.readingSound.soundUrl.isContained ? $0.recording.id : nil
                        }
                        return data.details
                            .filter { oldArchivedMeditationsIds.contains($0.recording.id) }
                            .flatMap { detail -> [URL] in
                                if let ambient = detail.ambientSound?.soundUrl {
                                    return [detail.readingSound.soundUrl, ambient]
                                }
                                return [detail.readingSound.soundUrl]
                            }
                    }
                    .flatMap { audios in
                        Observable
                            .combineLatest(
                                saveMeditations.asObservable(),
                                saveDetails.asObservable(),
                                removeMeditations.asObservable(),
                                removeDetails.asObservable()
                            ) { _, _, _, _ -> (images: [URL], audios: [URL]) in
                                let images = data.meditations.reduce([]) { urls, meditation -> [URL] in
                                    var result = urls
                                    if let imagePreviewUrl = meditation.imagePreviewUrl { result.append(imagePreviewUrl) }
                                    if let imageReaderURL = meditation.imageReaderURL { result.append(imageReaderURL) }
                                    return result
                                }
                                return (images, audios)
                            }
                    }
                    .flatMap { [weak self] tuple -> Single<Void> in
                        guard let self = self else {
                            return .just(())
                        }
                        return Single.zip(
                            self.downloadImagesService.downloadImages(urls: tuple.images),
                            MediaCacheService().copy(urls: tuple.audios)
                                .catchErrorJustReturn(())
                        ) { _, _ in () }
                    }
                    .observeOn(MainScheduler.instance)
                    .do(onNext: {
                        CacheHashCodes.meditationsHashCode = data.meditationsHashCode
                    })
            }
    }
    
    func updateTags() -> Observable<Void> {
        return SDKStorage.shared
            .restApiTransport
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
    
    var wasCopied: Bool {
        set { UserDefaults.standard.set(true, forKey: "stories_was_copied_in_db_key_v2") }
        get { return UserDefaults.standard.bool(forKey: "stories_was_copied_in_db_key_v2") }
    }
    
    func copyStories() -> Observable<Void> {
        guard !wasCopied else {
            return Observable<Void>.just(Void())
        }
        
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
                    .map { _ in Void() }
                    .do(onNext: { [weak self] in
                        self?.copyImagesService.backgroundCopyImages(copingLocalImages: data.copingLocalImages)
                        self?.wasCopied = true
                        CacheHashCodes.storiesHashCode = data.storiesHashCode
                    })
            }
    }
    
    func update() -> Observable<Void> {
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: FullStoriesListRequest(hashCode: CacheHashCodes.storiesHashCode))
            .asObservable()
            .map { StoriesMapper.fullStories(response: $0) }
            .flatMap { fullStories -> Observable<Void> in
                guard let data = fullStories else {
                    return .error(RxError.noElements)
                }
                
                let oldStories = RealmDBTransport().loadData(
                    realmType: RealmStoryDetail.self,
                    map: StoryDetailRealmMapper.map
                )
                let saveStories = RealmDBTransport().saveData(entities: data.stories, map: { StoryRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { try! StoryDetailRealmMapper.map(from: $0) })
                let removeStories = RealmDBTransport().deleteData(realmType: RealmStory.self, filter: NSPredicate(format: "id IN %@", data.deletedStoryIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmStoryDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedStoryIds))
                
                return oldStories.asObservable()
                    .catchErrorJustReturn([])
                    .map { stories -> [URL] in
                        let oldArchivedStoriesIds = stories.compactMap {
                            $0.readingSound.soundUrl.isContained ? $0.recording.id : nil
                        }
                        return data.details
                            .filter { oldArchivedStoriesIds.contains($0.recording.id) }
                            .flatMap { detail -> [URL] in
                                if let ambient = detail.ambientSound?.soundUrl {
                                    return [detail.readingSound.soundUrl, ambient]
                                }
                                return [detail.readingSound.soundUrl]
                            }
                    }
                    .flatMap { audios in
                        Observable
                            .combineLatest(
                                saveStories.asObservable(),
                                saveDetails.asObservable(),
                                removeStories.asObservable(),
                                removeDetails.asObservable()
                            ) { _, _, _, _ -> (images: [URL], audios: [URL]) in
                                let images = data.stories.reduce([]) { urls, story -> [URL] in
                                    var result = urls
                                    if let imagePreviewUrl = story.imagePreviewUrl { result.append(imagePreviewUrl) }
                                    if let imageReaderURL = story.imageReaderURL { result.append(imageReaderURL) }
                                    return result
                                }
                                return (images, audios)
                            }
                    }
                    .flatMap { [weak self] tuple -> Single<Void> in
                        guard let self = self else {
                            return .just(())
                        }
                        return Single.zip(
                            self.downloadImagesService.downloadImages(urls: tuple.images),
                            MediaCacheService().copy(urls: tuple.audios)
                                .catchErrorJustReturn(())
                        ) { _, _ in () }
                    }
                    .observeOn(MainScheduler.instance)
                    .do(onNext: {
                        CacheHashCodes.storiesHashCode = data.storiesHashCode
                    })
            }
    }
}

private final class CacheScenes: Copy {
    private let downloadImagesService = DownloadImagesService()
    private let copyImagesService = CopyImagesService()
    
    var wasCopied: Bool {
        set { UserDefaults.standard.set(true, forKey: "scenes_was_copied_in_db_key_v2") }
        get { return UserDefaults.standard.bool(forKey: "scenes_was_copied_in_db_key_v2") }
    }
    
    func copyScenes() -> Observable<Void> {
        guard !wasCopied else {
            return Observable<Void>.just(Void())
        }
        
        let fullScenes = whatCopy(resource: "scenes", map: { ScenesMapper.fullScenes(response: $0) })
        
        return fullScenes
            .flatMap { fullScenes -> Observable<Void> in
                guard let data = fullScenes else {
                    return .error(RxError.noElements)
                }

                let saveScenes = RealmDBTransport().saveData(entities: data.scenes, map: { SceneRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { SceneDetailRealmMapper.map(from: $0) })
                
                return Observable
                    .combineLatest(saveScenes.asObservable(),
                                   saveDetails.asObservable())
                    .map { _ in Void() }
                    .do(onNext: { [weak self] in
                        self?.copyImagesService.backgroundCopyImages(copingLocalImages: data.copingLocalImages)
                        self?.wasCopied = true 
                        CacheHashCodes.scenesHashCode = data.scenesHashCode
                    })
            }
    }
    
    func update() -> Observable<Void> {
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: FullScenesListRequest(hashCode: CacheHashCodes.scenesHashCode))
            .asObservable()
            .map { ScenesMapper.fullScenes(response: $0) }
            .flatMap { fullScenes -> Observable<Void> in
                guard let data = fullScenes else {
                    return .error(RxError.noElements)
                }
                
                let oldScenes = RealmDBTransport().loadData(
                    realmType: RealmSceneDetail.self,
                    map: SceneDetailRealmMapper.map
                )
                let saveScenes = RealmDBTransport().saveData(entities: data.scenes, map: { SceneRealmMapper.map(from: $0) })
                let saveDetails = RealmDBTransport().saveData(entities: data.details, map: { SceneDetailRealmMapper.map(from: $0) })
                let removeScenes = RealmDBTransport().deleteData(realmType: RealmScene.self, filter: NSPredicate(format: "id IN %@", data.deletedSceneIds))
                let removeDetails = RealmDBTransport().deleteData(realmType: RealmSceneDetail.self, filter: NSPredicate(format: "id IN %@", data.deletedSceneIds))
                
                return oldScenes.asObservable()
                    .catchErrorJustReturn([])
                    .map { scenes -> [URL] in
                        let oldArchivedSceneAudioIds = scenes.compactMap { scene -> Int? in
                            guard let sound = scene.sounds.first?.soundUrl else {
                                return nil
                            }
                            return sound.isContained ? scene.scene.id : nil
                        }
                        
                        let oldArchivedSceneVideoIds = scenes.compactMap {
                            $0.scene.url.isContained ? $0.scene.id : nil
                        }
                        
                        let audios = data.details
                            .filter { oldArchivedSceneAudioIds.contains($0.scene.id) }
                            .flatMap { $0.sounds.map { $0.soundUrl } }
                        
                        let videos = data.details
                            .filter { $0.scene.mime.isVideo && oldArchivedSceneVideoIds.contains($0.scene.id) }
                            .map { $0.scene.url }
                        
                        return audios + videos
                    }
                    .flatMap { media in
                        Observable
                            .combineLatest(
                                saveScenes.asObservable(),
                                saveDetails.asObservable(),
                                removeScenes.asObservable(),
                                removeDetails.asObservable()
                            ) { _, _, _, _ -> (media: [URL], images: [URL]) in
                                let images = data.scenes.filter { $0.mime.isImage }
                                    .map { $0.url }
                                return (media, images)
                            }
                    }
                    .flatMap { [weak self] tuple -> Single<Void> in
                        guard let self = self else {
                            return .just(())
                        }
                        return Single.zip(
                            self.downloadImagesService.downloadImages(urls: tuple.images),
                            MediaCacheService().copy(urls: tuple.media)
                                .catchErrorJustReturn(())
                        ) { _, _ in () }
                    }
                    .observeOn(MainScheduler.instance)
                    .do(onNext: {
                        CacheHashCodes.scenesHashCode = data.scenesHashCode
                    })
            }
    }
}

private final class CacheNoise: Copy {
    private let downloadImagesService = DownloadImagesService()
    private let copyImageService = CopyImagesService()
    
    var wasCopied: Bool {
        set { UserDefaults.standard.set(true, forKey: "noises_was_copied_in_db_key_v2") }
        get { UserDefaults.standard.bool(forKey: "noises_was_copied_in_db_key_v2") }
    }
    
    func copyNoises() -> Observable<Void> {
        guard !wasCopied else {
            return .just(Void())
        }

        let fullNoises = whatCopy(resource: "sound_categories", map: { NoiseMapper.fullNoises(response: $0) })

        return fullNoises
            .flatMap { fullNoises -> Single<Void> in
                guard let data = fullNoises else {
                    return .error(RxError.noElements)
                }

                return RealmDBTransport()
                    .saveData(entities: data.noiseCategories, map: { NoiseCategoryRealmMapper.map(from: $0) })
                .do(onSuccess: { [unowned self] in
                    self.copyImageService.backgroundCopyImages(copingLocalImages: data.copingLocalImages)
                    self.wasCopied = true
                    CacheHashCodes.noiseCategoriesHashCode = data.noisesHashCode
                })
            }
    }
    
    func update() -> Observable<Void> {
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: GetNoiseCategoriesRequest(hashCode: CacheHashCodes.noiseCategoriesHashCode))
            .asObservable()
            .map { NoiseMapper.fullNoises(response: $0) }
            .flatMap { fullNoises -> Observable<Void> in
                guard let data = fullNoises else {
                    return .error(RxError.noElements)
                }
                
                let saveCategories = RealmDBTransport().saveData(entities: data.noiseCategories, map: { NoiseCategoryRealmMapper.map(from: $0) })
                let removeCategories = RealmDBTransport().deleteData(realmType: RealmNoiseCategory.self, filter: NSPredicate(format: "id IN %@", data.deletedNoiseCategoryIds))
                let removeNoises = RealmDBTransport().deleteData(realmType: RealmNoise.self, filter: NSPredicate(format: "id IN %@", data.deletedNoiseIds))
                
                return RealmDBTransport()
                    .loadData(realmType: RealmNoiseSound.self, map: { NoiseSoundRealmMapper.map(from: $0) })
                    .catchErrorJustReturn([])
                    .map { noiseSounds -> [URL] in
                        let soundsWhereContainedCachedAudio = noiseSounds
                            .filter { $0.soundUrl.isContained }
                            .map { $0.id }
                        
                        return data.noiseCategories
                            .flatMap {
                                $0.noises
                                    .reduce([]) { $0 + $1.sounds }
                                    .filter { soundsWhereContainedCachedAudio.contains($0.id) }
                                    .map { $0.soundUrl }
                            }
                    }
                    .flatMap { audioUrlsForUpdate -> Single<Void> in
                        return Single
                            .zip(
                                saveCategories,
                                removeCategories,
                                removeNoises
                            )
                            .map { _ -> [URL] in
                                return data.noiseCategories
                                    .flatMap {
                                        $0.noises
                                            .reduce([]) { $0 + [$1.imageUrl] }
                                    }
                            }
                            .flatMap { [unowned self] imageUrlsForUpdate -> Single<Void> in
                                return Single.zip(
                                    self.downloadImagesService.downloadImages(urls: imageUrlsForUpdate),
                                    MediaCacheService().copy(urls: audioUrlsForUpdate)
                                        .catchErrorJustReturn(())
                                ).map { _, _ in Void() }
                            }
                    }
                    .observeOn(MainScheduler.asyncInstance)
                    .asObservable()
                    .do(onNext: {
                        CacheHashCodes.noiseCategoriesHashCode = data.noisesHashCode
                    })
            }
    }
}

private final class CacheHashCodes {
    private static let meditationsHashCodeKey = "meditations_hash_code_key_v2"
    private static let storiesHashCodeKey = "stories_hash_code_key_v2"
    private static let scenesHashCodeKey = "scenes_hash_code_key_v2"
    private static let meditationTagsHashCodeKey = "meditation_tags_hash_code_key_v2"
    private static let noiseCategoriesHashCodeKey = "noise_categories_hash_code_key_v2"
    
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
    
    static var noiseCategoriesHashCode: String? {
        set(hashCode) {
            UserDefaults.standard.set(hashCode, forKey: noiseCategoriesHashCodeKey)
        }
        get {
            return UserDefaults.standard.string(forKey: noiseCategoriesHashCodeKey)
        }
    }
}
