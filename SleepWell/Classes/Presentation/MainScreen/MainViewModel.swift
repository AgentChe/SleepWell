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
    func monitorSubscriptionExpiration(triggers: [Observable<Void>]) -> Signal<Void>
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
        let meditationService: MeditationService
        let purchaseService: PurchaseService
    }
    
    func monitorSubscriptionExpiration(triggers: [Observable<Void>]) -> Signal<Void> {
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
            .flatMapLatest { isNeedPayment -> Observable<Void> in
                isNeedPayment ? .just(Void()) : .never()
            }
            .asSignal(onErrorSignalWith: .never())
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
