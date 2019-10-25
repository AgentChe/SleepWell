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
    
}

final class MainViewModel: BindableViewModel {
    typealias Interface = MainViewModelInterface
    
    lazy var router: MainRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension MainViewModel: MainViewModelInterface {
    
}
