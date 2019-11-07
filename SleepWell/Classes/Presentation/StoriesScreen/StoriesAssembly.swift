//
//  StoriesAssembly.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//


final class StoriesAssembly: ScreenAssembly {
    typealias VC = StoriesViewController
    
    func assembleDependencies() -> StoriesViewModel.Dependencies {
        return VC.ViewModel.Dependencies(storyService: StoryService())
    }
}
