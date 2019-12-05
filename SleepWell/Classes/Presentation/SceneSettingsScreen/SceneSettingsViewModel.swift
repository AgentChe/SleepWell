//
//  SceneSettingsViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxCocoa

protocol SceneSettingsViewModelInterface {
    var currentScenePlayersVolume: [(id: Int, value: Float)]? { get }
    var sceneVolume: Binder<(to: Int, value: Float)> { get }
    func showSleepTimerScreen(sceneDetail: SceneDetail)
}

final class SceneSettingsViewModel: BindableViewModel {
    typealias Interface = SceneSettingsViewModelInterface
    
    lazy var router: SceneSettingsRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioService: AudioPlayerService
    }
}

extension SceneSettingsViewModel: SceneSettingsViewModelInterface {
    
    var currentScenePlayersVolume: [(id: Int, value: Float)]? {
        dependencies.audioService.currentScenePlayersVolume
    }
    
    var sceneVolume: Binder<(to: Int, value: Float)> {
        dependencies.audioService.rx.sceneVolume
    }
    
    func showSleepTimerScreen(sceneDetail: SceneDetail) {
        router.showSleepTimerScreen(sceneDetail: sceneDetail)
    }
}
