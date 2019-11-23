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
    func sceneDetails(scene: SceneCellModel) -> Signal<ScenesViewModel.Action>
    func isPlaying(scene: SceneDetail) -> Driver<Bool>
    func add(sceneDetail: SceneDetail)
    var playScene: Binder<Void> { get }
    var pauseScene: Binder<Void> { get }
    func showSettings(sceneDetail: SceneDetail) -> Signal<Void>
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

    func sceneDetails(scene: SceneCellModel) -> Signal<Action> {
        guard scene.paid else {
            return .just(.paygate)
        }
        return dependencies.sceneService
            .getScene(by: scene.id)
            .map { Action.detail($0) }
            .catchError { error -> Single<Action> in
                guard (error as NSError).code == 403  else {
                    return .never()
                }
                return .just(.paygate)
            }.debug()
            .asSignal(onErrorSignalWith: .empty())
    }
    
    func isPlaying(scene: SceneDetail) -> Driver<Bool> {
        dependencies.audioPlayerService.isPlaying(scene: scene)
    }
    
    func add(sceneDetail: SceneDetail) {
        dependencies.audioPlayerService.add(sceneDetail: sceneDetail)
    }
    
    var playScene: Binder<Void> {
        dependencies.audioPlayerService.rx.playScene
    }
    
    var pauseScene: Binder<Void> {
        dependencies.audioPlayerService.rx.pauseScene
    }
    
    func showSettings(sceneDetail: SceneDetail) -> Signal<Void> {
        router.showSettings(sceneDetail: sceneDetail)
    }
}
