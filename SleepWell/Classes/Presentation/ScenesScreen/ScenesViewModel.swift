//
//  ScenesViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol ScenesViewModelInterface {
    func elements(subscription: Observable<Bool>) -> Driver<[SceneCellModel]>
    func sceneDetails(scene: SceneCellModelFields) -> Signal<ScenesViewModel.Action>
    func isPlaying(scene: SceneDetail) -> Driver<Bool>
    func isOtherScenePlaying(scene: SceneDetail) -> Bool
    var isScenePlaying: Driver<Bool> { get }
    func add(sceneDetail: SceneDetail) -> Signal<Void>
    func playScene(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void>
    func showSettings(sceneDetail: SceneDetail) -> Signal<Void>
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void>
    func copyVideo(url: URL) -> Signal<Void>
}

final class ScenesViewModel: BindableViewModel {
    enum Action {
        case paygate
        case detail(SceneDetail?)
        
        var sceneDetail: SceneDetail? {
            switch self {
            case .paygate:
                return nil
            case .detail(let detail):
                return detail
            }
        }
    }
    
    typealias Interface = ScenesViewModelInterface
    
    lazy var router: ScenesRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let sceneService: SceneService
        let audioPlayerService: AudioPlayerService
        let mediaCacheService: MediaCacheService
    }
}

extension ScenesViewModel: ScenesViewModelInterface {
    
    func elements(subscription: Observable<Bool>) -> Driver<[SceneCellModel]> {
        let scenes = dependencies.sceneService
            .scenes()
            .asDriver(onErrorJustReturn: [])
        
        return Driver
            .combineLatest(
                scenes,
                subscription.distinctUntilChanged().asDriver(onErrorJustReturn: false)
            )
            .map { SceneCellModel.map(scene: $0.0, isActiveSubscription: $0.1) }
    }

    func sceneDetails(scene: SceneCellModelFields) -> Signal<Action> {
        guard scene.paid else {
            return .just(.paygate)
        }
        return dependencies.sceneService
            .scene(by: scene.id)
            .map { Action.detail($0) }
            .catchError { error -> Single<Action> in
                guard (error as NSError).code == 403  else {
                    return .never()
                }
                return .just(.paygate)
            }
            .asSignal(onErrorSignalWith: .empty())
    }
    
    func isPlaying(scene: SceneDetail) -> Driver<Bool> {
        dependencies.audioPlayerService.isPlaying(scene: scene)
    }
    
    func isOtherScenePlaying(scene: SceneDetail) -> Bool {
        dependencies.audioPlayerService.isOtherScenePlaying(scene: scene)
    }
    
    var isScenePlaying: Driver<Bool> {
        dependencies.audioPlayerService.isScenePlaying
    }
    
    func add(sceneDetail: SceneDetail) -> Signal<Void> {
        dependencies.audioPlayerService.add(sceneDetail: sceneDetail)
    }
    
    func playScene(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioPlayerService.playScene(style: style)
    }
    
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioPlayerService.pauseScene(style: style)
    }
    
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioPlayerService.pauseRecording(style: style)
    }
    
    func showSettings(sceneDetail: SceneDetail) -> Signal<Void> {
        router.showSettings(sceneDetail: sceneDetail)
    }
    
    func copyVideo(url: URL) -> Signal<Void> {
        dependencies.mediaCacheService.copy(urls: [url])
            .asSignal(onErrorSignalWith: .empty())
    }
}
