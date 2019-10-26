//
//  PlayerScreenViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol PlayerScreenViewModelInterface {
}

final class PlayerScreenViewModel: BindableViewModel {
    typealias Interface = PlayerScreenViewModelInterface
    
    lazy var router: PlayerScreenRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension PlayerScreenViewModel: PlayerScreenViewModelInterface {
}
