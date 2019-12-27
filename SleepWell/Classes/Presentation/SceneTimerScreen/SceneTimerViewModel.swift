//
//  SceneTimerViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 29/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol SceneTimerViewModelInterface {
    func dismiss()
    var setTimer: Binder<Int> { get }
    var cancelTimer: Binder<Void> { get }
    var timerSeconds: Driver<Int> { get }
    var isTimerRunning: Driver<Bool> { get }
}

final class SceneTimerViewModel: BindableViewModel {
    
    typealias Interface = SceneTimerViewModelInterface
    
    lazy var router: SceneTimerRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioPlayerService: AudioPlayerService
    }
}

extension SceneTimerViewModel: SceneTimerViewModelInterface {
    
    func dismiss() {
        router.dismiss()
    }
    
    var setTimer: Binder<Int> {
        Analytics.shared.log(with: .sceneSleepTimerSet)
        
        return dependencies.audioPlayerService.rx.setTimer
    }
    
    var timerSeconds: Driver<Int> {
        dependencies.audioPlayerService.timerSeconds
    }
    
    var isTimerRunning: Driver<Bool> {
        dependencies.audioPlayerService.isTimerRunning
    }
    
    var cancelTimer: Binder<Void> {
        dependencies.audioPlayerService.rx.cancelTimer
    }
}
