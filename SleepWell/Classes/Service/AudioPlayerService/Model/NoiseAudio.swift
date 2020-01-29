//
//  NoiseAudio.swift
//  SleepWell
//
//  Created by Alexander Mironov on 15/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import AVFoundation.AVPlayer
import RxCocoa
import RxSwift

final class NoiseAudio: ReactiveCompatible {
    
    struct StatePlayer {
        let id: Int
        let player: AVPlayer
        let state: Driver<LoadState>
    }
    
    private(set) var statePlayers: [StatePlayer]
    
    init(statePlayers: [StatePlayer]) {
        self.statePlayers = statePlayers
        self.prepareRetry(players: self.statePlayers.map { $0.player })
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        if let player = statePlayers.first(where: { $0.id == id }) {
            player.player.volume = value
        }
    }
    
    func forcePause() {
        statePlayers.forEach {
            $0.player.pause()
        }
    }
    
    func pause() -> Signal<Void> {
        .deferred { [weak self] in
            self?.forcePause()
            return .just(())
        }
    }
    
    func play() {
        statePlayers.forEach {
            if $0.player.rate == 0 {
                $0.player.play()
            }
        }
    }
    
    func add(statePlayers: [StatePlayer]) {
        prepareRetry(players: statePlayers.map { $0.player })
        self.statePlayers.append(contentsOf: statePlayers)
    }
    
    func remove(ids: Set<Int>) {
        statePlayers = statePlayers.filter { !ids.contains($0.id) }
    }
    
    private func prepareRetry(players: [AVPlayer]) {
        players.forEach {
            NotificationCenter.default.rx
                .notification(
                    .AVPlayerItemDidPlayToEndTime,
                    object: $0.currentItem
                )
                .bind(to: Binder($0) { player, _ in
                    player.seek(to: CMTime.zero)
                    player.play()
                })
                .disposed(by: disposeBag)
        }
    }
    
    private let disposeBag = DisposeBag()
}
