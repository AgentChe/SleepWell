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
        let mainPlayer = AVPlayer(url: recording.readingSound.soundUrl)
        let ambientPlayer: AVPlayer?
        if let ambientUrl = recording.ambientSound?.soundUrl {
            ambientPlayer = AVPlayer(url: ambientUrl)
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
    
    var currentMainPlayerVolume: Float? {
        audioRelay.value?.mainPlayerVolume
    }
    
    var currentAmbientPlayerVolume: Float? {
        audioRelay.value?.ambientPlayerVolume
    }
    
    fileprivate let audioRelay = BehaviorRelay<Audio?>(value: nil)
    private init() {}
}

private final class Audio: ReactiveCompatible {
    let mainPlayer: AVPlayer
    let ambientPlayer: AVPlayer?
    let recording: RecordingDetail
    
    init(
        mainPlayer: AVPlayer,
        ambientPlayer: AVPlayer?,
        recording: RecordingDetail
    ) {
        self.mainPlayer = mainPlayer
        self.ambientPlayer = ambientPlayer
        self.recording = recording
    }
    
    var currentTime: CMTime {
        set {
            mainPlayer.seek(to: newValue, completionHandler: { _ in })
        }
        get {
            mainPlayer.currentTime()
        }
    }
    
    var mainPlayerVolume: Float {
        mainPlayer.volume
    }
    
    var ambientPlayerVolume: Float? {
        ambientPlayer?.volume
    }
    
    func setMainPlayerVolume(value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        mainPlayer.volume = value
    }
    
    func setAmbientPlayerVolume(value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        ambientPlayer?.volume = value
    }
    
    func prepareToPlay() {
        
        if let ambient = ambientPlayer {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: ambient.currentItem,
                queue: .main
            ) { _ in
                ambient.seek(to: CMTime.zero)
                ambient.play()
            }
        }
    }
    
    func play() {
        mainPlayer.play()
        ambientPlayer?.play()
    }
    
    func pause() {
        mainPlayer.pause()
        ambientPlayer?.pause()
    }
    
    func reset() {
        pause()
        currentTime = CMTime.zero
    }
}

extension Reactive where Base: AudioPlayerService {
    
    var play: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.play()
        }
    }
    
    var pause: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.pause()
        }
    }
    
    var clear: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.accept(nil)
        }
    }
    
    var setTime: Binder<Int> {
        
        Binder(base) { base, time in
            guard let audio = base.audioRelay.value else {
                return
            }
            audio.currentTime = CMTime(seconds: Double(time), preferredTimescale: 1)
        }
    }
    
    var reset: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.reset()
        }
    }
    
    var mainPlayerVolume: Binder<Float> {
        
        Binder(base) { base, value in
            base.audioRelay.value?.setMainPlayerVolume(value: value)
        }
    }
    
    var ambientPlayerVolume: Binder<Float> {
        
        Binder(base) { base, value in
            base.audioRelay.value?.setAmbientPlayerVolume(value: value)
        }
    }
}

private extension Reactive where Base: Audio {
    
    //Не поддерживает KVO, поэтому через таймер
    
    var currentTime: Driver<Int> {
        
        Driver<Int>.interval(.milliseconds(100))
            .map { [base] _ in
                Int(round(base.mainPlayer.currentTime().seconds))
            }
            .distinctUntilChanged()
    }
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.interval(.milliseconds(100))
            .map { [base] _ in
                base.mainPlayer.rate != 0 && base.mainPlayer.error == nil
            }
            .distinctUntilChanged()
    }
}
