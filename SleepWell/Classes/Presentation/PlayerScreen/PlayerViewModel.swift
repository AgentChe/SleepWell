//
//  PlayerViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol PlayerViewModelInterface {
    var setTime: Binder<TimeInterval> { get }
    var play: Binder<Void> { get }
    var reset: Binder<Void> { get }
    var time: Driver<Int> { get }
    func add(url: URL)
}

final class PlayerViewModel: BindableViewModel {
    typealias Interface = PlayerViewModelInterface
    
    lazy var router: PlayerRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioService: AudioPlayerService
    }
}

extension PlayerViewModel: PlayerViewModelInterface {
    
    var setTime: Binder<TimeInterval> {
        dependencies.audioService.rx.setTime
    }
    
    var play: Binder<Void> {
        dependencies.audioService.rx.play
    }
    
    var reset: Binder<Void> {
        dependencies.audioService.rx.reset
    }
    
    var time: Driver<Int> {
        dependencies.audioService.time
    }
    
    func add(url: URL) {
        dependencies.audioService.add(url: url)
    }
}
