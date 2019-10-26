//
//  AudioPlayerService.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation

final class AudioPlayerService {
    
    static let shared = AudioPlayerService()
    
    func play() {
        players.forEach {
            $0.play()
        }
    }
    
    func stop() {
        players.forEach {
            $0.stop()
        }
    }
    
    func add(url: URL) {
        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
            return
        }
        newPlayer.prepareToPlay()
        newPlayer.play()
        players.append(newPlayer)
    }
    
    func replace(with urls: [URL]) {
        players = urls.compactMap {
            try? AVAudioPlayer(contentsOf: $0)
        }
        play()
    }
    
    func clear() {
        players = []
    }
    
    private var players: [AVAudioPlayer] = []
    private init() {}
}
