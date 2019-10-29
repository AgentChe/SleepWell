//
//  AudioPlayerService.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation
import RxSwift
import RxCocoa

final class AudioPlayerService: ReactiveCompatible {
    
    static let shared = AudioPlayerService()
    
    func add(url: URL) {
        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
            return
        }
        newPlayer.prepareToPlay()
        players.accept(players.value.appending(newPlayer))
    }
    
    var time: Driver<Int> {
        
        //change for main audio
        return players.asDriver()
            .map { $0.first }
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest { $0.rx.currentTime }
    }
    
    fileprivate var players = BehaviorRelay<[AVAudioPlayer]>(value: [])
    private init() {}
}

extension Reactive where Base: AudioPlayerService {
    
    var play: Binder<Void> {
        
        Binder(base) { base, _ in
            base.players.value.forEach { $0.play() }
        }
    }
    
    var stop: Binder<Void> {
        
        Binder(base) { base, _ in
            base.players.value.forEach { $0.stop() }
        }
    }
    
    var reset: Binder<Void> {
        
        Binder(base) { base, _ in
            base.players.value.forEach {
                $0.stop()
                $0.currentTime = 0
            }
        }
    }
    
    var clear: Binder<Void> {
        
        Binder(base) { base, _ in
            base.players.accept([])
        }
    }
    
    var add: Binder<URL> {
        
        Binder(base) { base, url in
            guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
                return
            }
            newPlayer.prepareToPlay()
            newPlayer.play()
            base.players.accept(base.players.value.appending(newPlayer))
        }
    }
    
    var setTime: Binder<TimeInterval> {
        
        Binder(base) { base, time in
            //change for main audio
            guard let audio = base.players.value.first else {
                return
            }
            audio.currentTime = time
        }
    }
}

private extension Reactive where Base: AVAudioPlayer {
    
    var currentTime: Driver<Int> {
        
        //currentTime не поддерживает KVO, поэтому через таймер
        Driver<Int>.interval(.milliseconds(100))
            .map { [base] _ in
                Int(round(base.currentTime))
            }
            .distinctUntilChanged()
    }
}

private extension Array {
    
    func appending(_ element: Element) -> Array<Element> {
        var result = self
        result.append(element)
        return result
    }
}
