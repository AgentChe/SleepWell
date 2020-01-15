//
//  SoundsAssembly.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright (c) 2020 Andrey Chernyshev. All rights reserved.
//


final class SoundsAssembly: ScreenAssembly {
    typealias VC = SoundsViewController
    
    func assembleDependencies() -> SoundsViewModel.Dependencies {
        return VC.ViewModel.Dependencies(
            noiseService: NoiseService(),
            audioPlayerService: AudioPlayerService.shared,
            mediaCacheService: MediaCacheService()
        )
    }
}
