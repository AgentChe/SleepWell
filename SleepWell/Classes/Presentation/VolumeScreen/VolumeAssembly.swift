//
//  VolumeAssembly.swift
//  SleepWell
//
//  Created by Alexander Mironov on 10/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class VolumeAssembly: ScreenAssembly {
    typealias VC = VolumeViewController
    
    func assembleDependencies() -> VolumeViewModel.Dependencies {
        return VC.ViewModel.Dependencies(audioService: AudioPlayerService.shared)
    }
}
