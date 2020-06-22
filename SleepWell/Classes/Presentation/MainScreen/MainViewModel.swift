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
    func showPaygateScreen(from: PaygateViewModel.PaygateOpenedFrom, completion: ((PaygateCompletionResult) -> (Void))?)
    func monitorSubscriptionExpiration(triggers: [Observable<Void>]) -> Signal<Bool>
    var isPlaying: Driver<Bool> { get }
    func playRecording(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseNoise() -> Signal<Void>
    var playNoise: Binder<Void> { get }
}

final class MainViewModel: BindableViewModel, MainViewModelInterface {

    typealias Interface = MainViewModelInterface
    
    lazy var router: MainRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let personalDataService: PersonalDataService
        let audioService: AudioPlayerService
        let meditationService: MeditationService
        let purchaseService: PurchaseService
    }
    
    func monitorSubscriptionExpiration(triggers: [Observable<Void>]) -> Signal<Bool> {
        return dependencies
            .meditationService.randomPaidMeditation().asObservable()
            .flatMapLatest { meditation -> Observable<Int> in
                guard let id = meditation?.id else {
                    return .never()
                }
                
                return Observable<Void>
                    .merge(triggers)
                    .map { id }
            }
            .flatMapLatest { [dependencies] meditationId in
                return dependencies.purchaseService
                    .isNeedPayment(by: meditationId)
                    .catchError { _ in .never() }
            }
            .asSignal(onErrorSignalWith: .never())
    }
    
    func sendPersonalData() -> Signal<Bool> {
        return dependencies.personalDataService
            .sendPersonalData()
            .map { true }
            .asSignal(onErrorJustReturn: true)
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
    
    func showPaygateScreen(from: PaygateViewModel.PaygateOpenedFrom, completion: ((PaygateCompletionResult) -> (Void))?) {
        router.showPaygateScreen(from: from, completion: completion)
    }
    
    var isPlaying: Driver<Bool> {
        dependencies.audioService.isPlaying
    }
    
    func playRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.playRecording(style: style)
    }
    
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.pauseRecording(style: style)
    }
    
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.pauseScene(style: style)
    }
    
    func pauseNoise() -> Signal<Void> {
        dependencies.audioService.pauseNoise()
    }
    
    var playNoise: Binder<Void> {
        dependencies.audioService.rx.playNoise
    }
}
