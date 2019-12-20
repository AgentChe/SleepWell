//
//  RecordingAudio.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift

final class RecordingAudio: ReactiveCompatible {
    
    let mainPlayer: VLCMediaPlayer
    let ambientPlayer: VLCMediaPlayer?
    let recording: RecordingDetail
    
    init(
        mainPlayer: VLCMediaPlayer,
        ambientPlayer: VLCMediaPlayer?,
        recording: RecordingDetail
    ) {
        self.mainPlayer = mainPlayer
        self.ambientPlayer = ambientPlayer
        self.recording = recording
    }
    
    var currentTime: VLCTime {
        set {
            mainPlayer.time = newValue
        }
        get {
            mainPlayer.time
        }
    }
    
    var mainPlayerVolume: Float {
        _mainPlayerVolume.value
    }
    
    var ambientPlayerVolume: Float? {
        _ambientPlayerVolume.value
    }
    
    func setMainPlayerVolume(value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        guard value != 0 else {
            _mainPlayerVolume.accept(value)
            mainPlayer.audio.volume = 0
            return
        }
        _mainPlayerVolume.accept(value)
        mainPlayer.audio.volume = Int32(100 * value) + 20
    }
    
    func setAmbientPlayerVolume(value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        guard value != 0 else {
            _ambientPlayerVolume.accept(value)
            ambientPlayer?.audio.volume = 0
            return
        }
        _ambientPlayerVolume.accept(value)
        ambientPlayer?.audio.volume = Int32(100 * value) + 20
    }
    
    func prepareToPlay() {
        
        setMainPlayerVolume(value: 0.75)
        setAmbientPlayerVolume(value: 0.75)
    }
    
    private func prepareAmbient() {
//        if let ambient = ambientPlayer {
//
//            NotificationCenter.default.rx
//                .notification(
//                    .AVPlayerItemDidPlayToEndTime,
//                    object: ambient.currentItem
//                )
//                .bind(to: Binder(ambient) { player, _ in
//                    player.seek(to: CMTime.zero)
//                    player.play()
//                })
//                .disposed(by: disposeBag)
//        }
    }
    
    func play(style: PlayAndPauseStyle) -> Signal<Void> {
        switch style {
        case .force:
            return .deferred { [weak self] in
                self?.forcePlay()
                return .just(())
            }
        case .gentle:
            
            let initialMainVolume = _mainPlayerVolume.value
            let initialAmbientVolume = _ambientPlayerVolume.value
            mainPlayer.audio.volume = 0
            ambientPlayer?.audio.volume = 0
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
                    guard let audio = self else {
                        return
                    }
                    audio.mainPlayer.audio.volume = Int32(progress * initialMainVolume) * 100
                    audio.ambientPlayer?.audio.volume = Int32(progress * initialAmbientVolume) * 100
                })
                .takeUntil(isPausing.asObservable())
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func pause(style: PlayAndPauseStyle) -> Signal<Void> {
        
        isPausing.accept(())
        mainPlayer.audio.volume = _mainPlayerVolume.value == 0
            ? 0 : Int32(_mainPlayerVolume.value * 100) + 20
        ambientPlayer?.audio.volume = _ambientPlayerVolume.value == 0
            ? 0 : Int32(_ambientPlayerVolume.value * 100) + 20
        
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
            
            let initialMainVolume = mainPlayer.audio.volume
            let initialAmbientVolume = ambientPlayer?.audio.volume ?? 0
            
            return Observable<Int>
                .timer(
                    .milliseconds(0),
                    period: .milliseconds(10),
                    scheduler: MainScheduler.instance
                )
                .take(101)
                .map { 1.0 - Float($0) / 100.0 }
                .do(onNext: { [weak self] progress in
                    guard let audio = self else {
                        return
                    }
                    audio.mainPlayer.audio.volume = progress == 0
                        ? 0 : Int32(progress * Float(initialMainVolume * 100))
                    audio.ambientPlayer?.audio.volume = progress == 0
                        ? 0 : Int32(progress * Float(initialAmbientVolume * 100))
                    if progress == 0.0 {
                        audio.forcePause()
                        audio.mainPlayer.audio.volume = initialMainVolume
                        audio.ambientPlayer?.audio.volume = initialAmbientVolume
                    }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func reset() {
        forcePause()
        currentTime = VLCTime(int: 0)
        ambientPlayer?.time = VLCTime(int: 0)
    }
    
    func forcePause() {
        mainPlayer.pause()
        ambientPlayer?.pause()
    }
    
    func forcePlay() {
        mainPlayer.play()
        ambientPlayer?.play()
    }
    
    func fastForward() {
        let seconds = mainPlayer.time.intValue
        let time = min(seconds + 15000, Int32(recording.readingSound.soundSecs * 1000))
        currentTime = VLCTime(int: time)
    }
    
    func rewind() {
        let seconds = mainPlayer.time.intValue
        let time = max(seconds - 15000, 0)
        currentTime = VLCTime(int: time)
    }
    
    var isPlaying: Bool {
        mainPlayer.isPlaying
    }
    
    private let _mainPlayerVolume = BehaviorRelay<Float>(value: 0.75)
    private let _ambientPlayerVolume = BehaviorRelay<Float>(value: 0.75)
    private let isPausing = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
}

extension Reactive where Base: RecordingAudio {
    
    //Не поддерживает KVO, поэтому через таймер
    
    var currentTime: Driver<Int> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [base] _ in
                Int(base.mainPlayer.time.intValue / 1000)
            }
            .distinctUntilChanged()
    }
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [base] _ in
                base.mainPlayer.isPlaying
            }
            .distinctUntilChanged()
    }
}
