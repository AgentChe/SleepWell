//
//  ScenesAssembly.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//


final class ScenesAssembly: ScreenAssembly {
    typealias VC = ScenesViewController
    
    func assembleDependencies() -> ScenesViewModel.Dependencies {
        return VC.ViewModel.Dependencies(sceneService: SceneService())
    }
}
