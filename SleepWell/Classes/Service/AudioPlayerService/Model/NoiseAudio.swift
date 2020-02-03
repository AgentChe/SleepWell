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
    
    private(set) var audioPlayers: [AudioPlayer]
    
    init(audioPlayers: [AudioPlayer]) {
        self.audioPlayers = audioPlayers
        self.prepare(players: self.audioPlayers.map { $0.player })
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        if let player = audioPlayers.first(where: { $0.id == id }) {
            player.player.volume = value
        }
    }
    
    func forcePause() {
        audioPlayers.forEach {
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
        audioPlayers.forEach {
            if !$0.player.isPlaying {
                $0.player.play()
            }
        }
    }
    
    func add(audioPlayers: [AudioPlayer]) {
        prepare(players: audioPlayers.map { $0.player })
        self.audioPlayers.append(contentsOf: audioPlayers)
    }
    
    func remove(ids: Set<Int>) {
        audioPlayers = audioPlayers.filter { !ids.contains($0.id) }
    }
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [weak self] _ in
                self?._isPlaying ?? false
            }
            .distinctUntilChanged()
    }
    
    var _isPlaying: Bool {
        audioPlayers.first?.player.isPlaying ?? false
    }
    
    private func prepare(players: [AVAudioPlayer]) {
        players.forEach {
            $0.prepareToPlay()
            $0.numberOfLoops = -1
        }
    }
    
    private let disposeBag = DisposeBag()
}
