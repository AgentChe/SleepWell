//
//  SceneAudio.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift

final class SceneAudio: ReactiveCompatible {
    
    class Player {
        var player: VLCMediaPlayer
        let id: Int
        
        init(player: VLCMediaPlayer, id: Int) {
            self.player = player
            self.id = id
        }
    }
    
    var players: [Player]
    let scene: Scene
    
    init(players: [Player], scene: Scene) {
        self.players = players
        self.scene = scene
    }
    
    func prepareToPlay() {
        
        players.forEach {
            $0.player.audio.volume = 75
        }
        let volumes = players.reduce([Int: Float]()) { result, player in
            var result = result
            result[player.id] = 0.75
            return result
        }
        _currentScenePlayersVolume.accept(volumes)
        prepareRetry()
    }
    
    func prepareRetry() {
        
        players.forEach { player in
            
            Observable<Int32>
                .timer(
                    .seconds(0),
                    period: .milliseconds(200),
                    scheduler: MainScheduler.instance
                )
                .map { _ -> Bool in
                    print(abs(player.player.remainingTime.intValue))
                    return abs(player.player.remainingTime.intValue) < 5000
                        && player.player.time.intValue != 0
                }
                .filter { $0 }
                .subscribe(onNext: { _ in
                    player.player.time = .init(int: 0)
                    player.player.play()
                })
                .disposed(by: disposeBag)
        }
    }
    
    func play(style: PlayAndPauseStyle) -> Signal<Void> {
        switch style {
        case .force:
            return .deferred { [weak self] in
                self?.forcePlay()
                return .just(())
            }
        case .gentle:
            let initialVolumes = players.map { $0.player.audio.volume }
            players.forEach { $0.player.audio.volume = 0 }
            forcePlay()
            
            return Observable<Int>
                .timer(
                    .milliseconds(0),
                    period: .milliseconds(10),
                    scheduler: MainScheduler.instance
                )
                .take(101)
                .map { Float($0) / 100.0 }
                .do(onNext: { [weak self] progress in
                    guard let scene = self else {
                        return
                    }
                    scene.players.enumerated()
                        .forEach { index, player in
                            guard let initialVolume = initialVolumes.item(at: index) else {
                                return
                            }
                            player.player.audio.volume = Int32(progress * Float(initialVolume))
                        }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func pause(style: PlayAndPauseStyle) -> Signal<Void> {
        switch style {
        case .force:
            return .deferred { [weak self] in
                self?.forcePause()
                return .just(())
            }
            
        case .gentle:
            
            guard isPlaying else {
                return .just(())
            }
            
            let initialVolumes = players.map { $0.player.audio.volume }
            return Observable<Int>
                .timer(
                    .milliseconds(0),
                    period: .milliseconds(10),
                    scheduler: MainScheduler.instance
                )
                .take(101)
                .map { 1.0 - Float($0) / 100.0 }
                .do(onNext: { [weak self] progress in
                    guard let scene = self else {
                        return
                    }
                    scene.players.enumerated()
                        .forEach { index, player in
                            guard let initialVolume = initialVolumes.item(at: index) else {
                                return
                            }
                            player.player.audio.volume = Int32(progress * Float(initialVolume * 100))
                        }
                    
                    if progress == 0.0 {
                        scene.forcePause()
                        
                        scene.players.enumerated()
                            .forEach { index, player in
                                guard let initialVolume = initialVolumes.item(at: index) else {
                                    return
                                }
                                player.player.audio.volume = initialVolume
                            }
                    }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        if let player = players.first(where: { $0.id == id }) {
            player.player.audio.volume = value == 0 ? 0 : Int32(100 * value) + 20
            var newVolumes = _currentScenePlayersVolume.value
            newVolumes[id] = value
            _currentScenePlayersVolume.accept(newVolumes)
        }
    }
    
    var isPlaying: Bool {
        guard let player = players.first?.player else {
            return false
        }
        return player.isPlaying
    }
    
    func forcePause() {
        players.forEach {
            $0.player.pause()
        }
    }
    
    func forcePlay() {
        players.forEach {
            $0.player.play()
        }
    }
    
    var currentScenePlayersVolume: [Int: Float] {
        _currentScenePlayersVolume.value
    }
    
    let disposeBag = DisposeBag()
    private let _currentScenePlayersVolume = BehaviorRelay<[Int: Float]>(value: [:])
}

extension Reactive where Base: SceneAudio {
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [base] _ in
                base.isPlaying
            }
            .distinctUntilChanged()
    }
}
