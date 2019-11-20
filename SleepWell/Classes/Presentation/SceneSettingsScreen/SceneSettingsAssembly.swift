//
//  SceneSettingsAssembly.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class SceneSettingsAssembly: ScreenAssembly {
    typealias VC = SceneSettingsViewController
    
    func assembleDependencies() -> SceneSettingsViewModel.Dependencies {
        return VC.ViewModel.Dependencies(audioService: AudioPlayerService.shared)
    }
}
