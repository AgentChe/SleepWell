//
//  SceneTimerAssembly.swift
//  SleepWell
//
//  Created by Alexander Mironov on 29/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class SceneTimerAssembly: ScreenAssembly {
    typealias VC = SceneTimerViewController
    
    func assembleDependencies() -> SceneTimerViewModel.Dependencies {
        return VC.ViewModel.Dependencies(
            audioPlayerService: AudioPlayerService.shared
        )
    }
}
