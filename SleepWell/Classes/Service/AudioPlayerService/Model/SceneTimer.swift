//
//  SceneTimer.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift

final class SceneTimer {
    
    func start(with seconds: Int) {
        disposeBag = DisposeBag()
        
        let timer = Driver<Int>.timer(.seconds(0), period: .seconds(1))
            .map { seconds - $0 }
            .take(seconds + 1)
        
        timer.drive(_currentSeconds)
            .disposed(by: disposeBag)
        
        timer.filter { $0 == 0 }
            .take(1)
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: _shouldSleep)
            .disposed(by: disposeBag)
    }
    
    func cancel() {
        disposeBag = DisposeBag()
        _currentSeconds.accept(0)
    }
    
    var isRunning: Driver<Bool> {
        
        _currentSeconds.asDriver()
            .map { $0 != 0 }
            .distinctUntilChanged()
    }
    
    var currentSeconds: Driver<Int> {
        _currentSeconds.asDriver()
    }
    
    var shouldSleep: Signal<Void> {
        _shouldSleep.asSignal()
    }
    
    private let _currentSeconds = BehaviorRelay<Int>(value: 0)
    private let _shouldSleep = PublishRelay<Void>()
    private var disposeBag = DisposeBag()
}
