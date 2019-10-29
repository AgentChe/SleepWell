//
//  PlayerAssembly.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class PlayerAssembly: ScreenAssembly {
    typealias VC = PlayerViewController
    
    func assembleDependencies() -> PlayerViewModel.Dependencies {
        return VC.ViewModel.Dependencies(audioService: AudioPlayerService.shared)
    }
}
