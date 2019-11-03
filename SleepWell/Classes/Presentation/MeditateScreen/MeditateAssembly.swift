//
//  MeditateAssembly.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//


final class MeditateAssembly: ScreenAssembly {
    typealias VC = MeditateViewController
    
    func assembleDependencies() -> MeditateViewModel.Dependencies {
        return VC.ViewModel.Dependencies()
    }
}
