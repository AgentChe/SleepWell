//
//  PlayerScreenAssembly.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class PlayerScreenAssembly: ScreenAssembly {
    typealias VC = PlayerScreenViewController
    
    func assembleDependencies() -> PlayerScreenViewModel.Dependencies {
        return VC.ViewModel.Dependencies()
    }
}
