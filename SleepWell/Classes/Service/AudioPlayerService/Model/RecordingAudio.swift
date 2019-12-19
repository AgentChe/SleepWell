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
            mainPlayer.seek(to: newValue)
        }
        get {
            mainPlayer.currentTime()
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
        _mainPlayerVolume.accept(value)
        mainPlayer.volume = value
    }
    
    func setAmbientPlayerVolume(value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        _ambientPlayerVolume.accept(value)
        ambientPlayer?.volume = value
    }
    
    func prepareToPlay() {
        
        setMainPlayerVolume(value: 0.75)
        setAmbientPlayerVolume(value: 0.75)
    }
    
    private func prepareAmbient() {
        if let ambient = ambientPlayer {
            
            NotificationCenter.default.rx
                .notification(
                    .AVPlayerItemDidPlayToEndTime,
                    object: ambient.currentItem
                )
                .bind(to: Binder(ambient) { player, _ in
                    player.seek(to: CMTime.zero)
                    player.play()
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
            
            let initialMainVolume = _mainPlayerVolume.value
            let initialAmbientVolume = _ambientPlayerVolume.value
            mainPlayer.volume = 0
            ambientPlayer?.volume = 0
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
                    audio.mainPlayer.volume = progress * initialMainVolume
                    audio.ambientPlayer?.volume = progress * initialAmbientVolume
                })
                .takeUntil(isPausing.asObservable())
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func pause(style: PlayAndPauseStyle) -> Signal<Void> {
        
        isPausing.accept(())
        mainPlayer.volume = _mainPlayerVolume.value
        ambientPlayer?.volume = _ambientPlayerVolume.value
        
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
            
            let initialMainVolume = mainPlayer.volume
            let initialAmbientVolume = ambientPlayer?.volume ?? 0
            
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
                    audio.mainPlayer.volume = progress * initialMainVolume
                    audio.ambientPlayer?.volume = progress * initialAmbientVolume
                    if progress == 0.0 {
                        audio.forcePause()
                        audio.mainPlayer.volume = initialMainVolume
                        audio.ambientPlayer?.volume = initialAmbientVolume
                    }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func reset() {
        forcePause()
        currentTime = .zero
        ambientPlayer?.seek(to: .zero)
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
        let seconds = Int(round(mainPlayer.currentTime().seconds))
        let time = min(seconds + 15, recording.readingSound.soundSecs)
        currentTime = CMTime(seconds: Double(time), preferredTimescale: 1)
    }
    
    func rewind() {
        let seconds = Int(round(mainPlayer.currentTime().seconds))
        let time = max(seconds - 15, 0)
        currentTime = CMTime(seconds: Double(time), preferredTimescale: 1)
    }
    
    var isPlaying: Bool {
        mainPlayer.rate == 1
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
                Int(round(base.mainPlayer.currentTime().seconds))
            }
            .distinctUntilChanged()
    }
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [base] _ in
                base.mainPlayer.rate != 0 && base.mainPlayer.error == nil
            }
            .distinctUntilChanged()
    }
}
