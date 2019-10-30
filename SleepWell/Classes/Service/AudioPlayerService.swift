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
    
    func add(recording: RecordingDetail) {
        guard let mainPlayer = try? AVAudioPlayer(contentsOf: recording.readingSound.soundUrl) else {
            return
        }
        let ambientPlayer: AVAudioPlayer?
        if let ambientUrl = recording.ambientSound?.soundUrl {
            ambientPlayer = try? AVAudioPlayer(contentsOf: ambientUrl)
        } else {
            ambientPlayer = nil
        }
        
        let audio = Audio(
            mainPlayer: mainPlayer,
            ambientPlayer: ambientPlayer,
            recording: recording
        )
        audio.prepareToPlay()
        audioRelay.accept(audio)
    }
    
    var time: Driver<Int> {
        
        audioRelay.asDriver()
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest { $0.rx.currentTime }
    }
    
    var isPlaying: Driver<Bool> {
        
        audioRelay.asDriver()
            .flatMapLatest {
                $0?.rx.isPlaying ?? .just(false)
            }
    }
    
    fileprivate let audioRelay = BehaviorRelay<Audio?>(value: nil)
    private init() {}
}

private final class Audio: ReactiveCompatible {
    let mainPlayer: AVAudioPlayer
    let ambientPlayer: AVAudioPlayer?
    let recording: RecordingDetail
    
    init(
        mainPlayer: AVAudioPlayer,
        ambientPlayer: AVAudioPlayer?,
        recording: RecordingDetail
    ) {
        self.mainPlayer = mainPlayer
        self.ambientPlayer = ambientPlayer
        self.recording = recording
    }
    
    var currentTime: TimeInterval {
        set {
            mainPlayer.currentTime = newValue
        }
        get {
            return mainPlayer.currentTime
        }
    }
    
    func prepareToPlay() {
        mainPlayer.prepareToPlay()
        mainPlayer.volume = 0.01
        ambientPlayer?.prepareToPlay()
        ambientPlayer?.numberOfLoops = -1
    }
    
    func play() {
        mainPlayer.play()
        ambientPlayer?.play()
    }
    
    func stop() {
        mainPlayer.stop()
        ambientPlayer?.stop()
    }
    
    func reset() {
        stop()
        mainPlayer.currentTime = 0
        ambientPlayer?.currentTime = 0
    }
}

extension Reactive where Base: AudioPlayerService {
    
    var play: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.play()
        }
    }
    
    var stop: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.stop()
        }
    }
    
    var clear: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.accept(nil)
        }
    }
    
    var setTime: Binder<TimeInterval> {
        
        Binder(base) { base, time in
            guard let audio = base.audioRelay.value else {
                return
            }
            audio.currentTime = time
        }
    }
    
    var reset: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.reset()
        }
    }
}

private extension Reactive where Base: Audio {
    
    //Не поддерживает KVO, поэтому через таймер
    
    var currentTime: Driver<Int> {
        
        Driver<Int>.interval(.milliseconds(100))
            .map { [base] _ in
                Int(round(base.mainPlayer.currentTime))
            }
            .distinctUntilChanged()
    }
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.interval(.milliseconds(100))
            .map { [base] _ in
                base.mainPlayer.isPlaying
            }
            .distinctUntilChanged()
    }
}
