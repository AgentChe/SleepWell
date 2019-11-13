//
//  MainScreenAssembly.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class MainAssembly: ScreenAssembly {
    typealias VC = MainViewController
    
    func assembleDependencies() -> MainViewModel.Dependencies {
        return VC.ViewModel.Dependencies(personalDataService: PersonalDataService())
    }
}
