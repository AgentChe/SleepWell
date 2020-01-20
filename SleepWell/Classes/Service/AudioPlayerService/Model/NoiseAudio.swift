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
    
    private(set) var players: [Player]
    
    init(players: [Player]) {
        self.players = players
        self.prepareRetry(players: self.players)
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        if let player = players.first(where: { $0.id == id }) {
            player.player.volume = value
        }
    }
    
    func forcePause() {
        players.forEach {
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
        players.forEach {
            if $0.player.rate == 0 {
                $0.player.play()
            }
        }
    }
    
    func add(players: [Player]) {
        prepareRetry(players: players)
        self.players.append(contentsOf: players)
    }
    
    func remove(ids: Set<Int>) {
        players = players.filter { !ids.contains($0.id) }
    }
    
    private func prepareRetry(players: [Player]) {
        players.forEach {
            NotificationCenter.default.rx
                .notification(
                    .AVPlayerItemDidPlayToEndTime,
                    object: $0.player.currentItem
                )
                .bind(to: Binder($0.player) { player, _ in
                    player.seek(to: CMTime.zero)
                    player.play()
                })
                .disposed(by: disposeBag)
        }
    }
    
    private let disposeBag = DisposeBag()
}
