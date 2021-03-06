//
//  SceneAudio.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation.AVPlayer
import RxCocoa
import RxSwift

final class SceneAudio: ReactiveCompatible {
    
    var players: [AudioPlayer]
    let scene: Scene
    
    init(players: [AudioPlayer], scene: Scene) {
        self.players = players
        self.scene = scene
    }
    
    func prepareToPlay() {
        let volumes = players.reduce([Int: Float]()) { result, player in
            var result = result
            result[player.id] = player.player.volume
            return result
        }
        _currentScenePlayersVolume.accept(volumes)
        prepare()
    }
    
    func play(style: PlayAndPauseStyle) -> Signal<Void> {
        switch style {
        case .force:
            return .deferred { [weak self] in
                self?.forcePlay()
                return .just(())
            }
        case .gentle:
            let initialVolumes = players.map { $0.player.volume }
            players.forEach { $0.player.volume = 0 }
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
                            player.player.volume = progress * initialVolume
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
            
            let initialVolumes = players.map { $0.player.volume }
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
                            player.player.volume = progress * initialVolume
                        }
                    
                    if progress == 0.0 {
                        scene.forcePause()
                        
                        scene.players.enumerated()
                            .forEach { index, player in
                                guard let initialVolume = initialVolumes.item(at: index) else {
                                    return
                                }
                                player.player.volume = initialVolume
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
            player.player.volume = value
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
    
    private func prepare() {
        players.forEach {
            $0.player.prepareToPlay()
            $0.player.numberOfLoops = -1
        }
    }
    
    private let _currentScenePlayersVolume = BehaviorRelay<[Int: Float]>(value: [:])
    private let disposeBag = DisposeBag()
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
