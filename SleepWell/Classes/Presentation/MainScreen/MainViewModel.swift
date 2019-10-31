//
//  MainViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol MainViewModelInterface {
    func selectTab(_ tab: MainViewModel.Tab)
}

final class MainViewModel: BindableViewModel {
    enum Tab {
        case meditate
        case stories
        case scenes
    }
    typealias Interface = MainViewModelInterface
    
    lazy var router: MainRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension MainViewModel: MainViewModelInterface {
    func selectTab(_ tab: MainViewModel.Tab) {
        switch tab {
        case .meditate:
            break
        case .stories:
            router.trigger(.stories)
        case .scenes:
            break
        }
    }
}
