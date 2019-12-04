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
    func sendPersonalData() -> Signal<Bool>
    func showPlayerScreen(
        detail: RecordingDetail,
        hideTabbarClosure: @escaping (Bool) -> Void,
        didStartPlaying: @escaping (String) -> Void,
        didPause: @escaping () -> Void
    )
    func showPaygateScreen(completion: ((PaygateCompletionResult) -> (Void))?)
    var isPlaying: Driver<Bool> { get }
    var play: Binder<Void> { get }
    var pause: Binder<Void> { get }
}

final class MainViewModel: BindableViewModel, MainViewModelInterface {

    typealias Interface = MainViewModelInterface
    
    lazy var router: MainRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let personalDataService: PersonalDataService
        let audioService: AudioPlayerService
    }
    
    func sendPersonalData() -> Signal<Bool> {
        return dependencies.personalDataService
            .sendPersonalData()
            .map { true }
            .asSignal(onErrorSignalWith: .never())
    }
    
    func showPlayerScreen(
        detail: RecordingDetail,
        hideTabbarClosure: @escaping (Bool) -> Void,
        didStartPlaying: @escaping (String) -> Void,
        didPause: @escaping () -> Void
    ) {
        router.showPlayerScreen(
            detail: detail,
            hideTabbarClosure: hideTabbarClosure,
            didStartPlaying: didStartPlaying,
            didPause: didPause
        )
    }
    
    func showPaygateScreen(completion: ((PaygateCompletionResult) -> (Void))?) {
        router.showPaygateScreen(completion: completion)
    }
    
    var isPlaying: Driver<Bool> {
        dependencies.audioService.isPlaying
    }
    
    var play: Binder<Void> {
        dependencies.audioService.rx.play
    }
    
    var pause: Binder<Void> {
        dependencies.audioService.rx.pause
    }
}
