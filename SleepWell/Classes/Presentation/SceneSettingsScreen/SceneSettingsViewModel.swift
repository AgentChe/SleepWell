//
//  SceneSettingsViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

protocol SceneSettingsViewModelInterface {}

final class SceneSettingsViewModel: BindableViewModel {
    typealias Interface = SceneSettingsViewModelInterface
    
    lazy var router: SceneSettingsRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioService: AudioPlayerService
    }
}

extension SceneSettingsViewModel: SceneSettingsViewModelInterface {}
