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
import MediaPlayer

enum PlayAndPauseStyle {
    case force
    case gentle
}

final class AudioPlayerService: ReactiveCompatible {
    
    static let shared = AudioPlayerService()
    
    func add(recording: RecordingDetail) {
        
        guard recording.recording.id != audioRelay.value?.recording.recording.id else {
            return
        }
        
        let mainPlayer = AVPlayer(url: recording.readingSound.soundUrl.localUrl)
        let ambientPlayer: AVPlayer?
        if let ambientUrl = recording.ambientSound?.soundUrl {
            ambientPlayer = AVPlayer(url: ambientUrl.localUrl)
        } else {
            ambientPlayer = nil
        }
        
        let audio = RecordingAudio(
            mainPlayer: mainPlayer,
            ambientPlayer: ambientPlayer,
            recording: recording
        )
        audioRelay.accept(audio)
        audio.prepareToPlay()
    }
    
    func add(recording: RecordingDetail) -> Signal<Void> {
        
        guard recording.recording.id != audioRelay.value?.recording.recording.id else {
            return .just(())
        }

        return .deferred { [weak self] in
            let mainPlayer = AVPlayer(url: recording.readingSound.soundUrl.localUrl)
            let ambientPlayer: AVPlayer?
            if let ambientUrl = recording.ambientSound?.soundUrl {
                ambientPlayer = AVPlayer(url: ambientUrl.localUrl)
            } else {
                ambientPlayer = nil
            }
            
            let audio = RecordingAudio(
                mainPlayer: mainPlayer,
                ambientPlayer: ambientPlayer,
                recording: recording
            )
            self?.audioRelay.accept(audio)
            audio.prepareToPlay()
            
            return .just(())
        }
    }

    func add(sceneDetail: SceneDetail) {
        guard sceneDetail.scene.id != sceneRelay.value?.scene.id
            && !sceneDetail.sounds.isEmpty else {
                return
        }
        
        let players = sceneDetail.sounds
            .map {
                Player(
                    player: AVPlayer(url: $0.soundUrl.localUrl),
                    id: $0.id
                )
            }
        
        let sceneAudio = SceneAudio(
            players: players,
            scene: sceneDetail.scene
        )
        sceneRelay.accept(sceneAudio)
        sceneAudio.prepareToPlay()
    }
    
    func add(noises: Set<NoiseSound>) -> Completable {
        let currentIds = Set(noiseRelay.value?.players.map { $0.id } ?? [])
        let addedIds = Set(noises.map { $0.id })
        let filtered = currentIds.intersection(addedIds)
        let removed = currentIds.subtracting(filtered)
        let newIds = addedIds.subtracting(filtered)
        noiseRelay.value?.remove(ids: removed)
        
        let newPlayers = noises.filter { newIds.contains($0.id) }
            .map {
                Player(
                    player: AVPlayer(url: $0.soundUrl.localUrl),
                    id: $0.id
                )
            }
        
        if let value = noiseRelay.value {
            value.add(players: newPlayers)
        } else {
            noiseRelay.accept(NoiseAudio(players: newPlayers))
        }
        
        noiseRelay.value?.play()
        
        return .empty()
    }
    
    func time(for id: Int) -> Driver<Int> {
        
        audioRelay.asDriver()
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest {
                $0.recording.recording.id == id
                    ? $0.rx.currentTime
                    : .just(0)
            }
    }
    
    func isPlaying(recording: RecordingDetail) -> Driver<Bool> {
        
        audioRelay.asDriver()
            .flatMapLatest {
                guard let value = $0, value.recording.recording.id == recording.recording.id else {
                    return .just(false)
                }
                return value.rx.isPlaying
            }
    }
    
    func isPlaying(scene: SceneDetail) -> Driver<Bool> {
        
        sceneRelay.asDriver()
            .flatMapLatest {
                guard let value = $0, value.scene.id == scene.scene.id else {
                    return .just(false)
                }
                return value.rx.isPlaying
            }
    }
    
    func isOtherScenePlaying(scene: SceneDetail) -> Bool {
        
        guard let value = sceneRelay.value, value.scene.id != scene.scene.id else {
            return false
        }
        return value.isPlaying
    }
    
    func playScene(style: PlayAndPauseStyle) -> Signal<Void> {
        sceneRelay.value?.play(style: style) ?? .just(())
    }
    
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void> {
        sceneRelay.value?.pause(style: style) ?? .just(())
    }
    
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        audioRelay.value?.pause(style: style) ?? .just(())
    }
    
    func playRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        audioRelay.value?.play(style: style) ?? .just(())
    }
    
    func pauseNoise() -> Signal<Void> {
        noiseRelay.value?.pause() ?? .just(())
    }
    
    var isScenePlaying: Driver<Bool> {
        
        sceneRelay.asDriver()
            .flatMapLatest {
                $0?.rx.isPlaying ?? .just(false)
            }
    }
    
    var isPlaying: Driver<Bool> {
        
        audioRelay.asDriver()
            .flatMapLatest {
                $0?.rx.isPlaying ?? .just(false)
            }
    }
    
    var timerSeconds: Driver<Int> {
        timer.currentSeconds
    }
    
    var isTimerRunning: Driver<Bool> {
        timer.isRunning
    }
    
    var currentMainPlayerVolume: Float? {
        audioRelay.value?.mainPlayerVolume
    }
    
    var currentAmbientPlayerVolume: Float? {
        audioRelay.value?.ambientPlayerVolume
    }
    
    var currentScenePlayersVolume: [(id: Int, value: Float)]? {
        sceneRelay.value?.currentScenePlayersVolume.map { (id: $0, value: $1) }
    }
    
    var didTapPlayRecording: Signal<RecordingDetail?> {
        audioRelay.flatMapLatest { recordingAudio -> Signal<RecordingDetail?> in
            recordingAudio?.didTapPlay.map { recordingAudio?.recording } ?? .never()
        }
        .asSignal(onErrorSignalWith: .never())
    }
    
    var playingForTwentySeconds: Signal<RecordingDetail?> {
        audioRelay.flatMapLatest { recordingAudio -> Signal<RecordingDetail?> in
            recordingAudio?.playingForTwentySeconds.map { recordingAudio?.recording } ?? .empty()
        }
        .asSignal(onErrorSignalWith: .never())
    }
    
    fileprivate let noiseRelay = BehaviorRelay<NoiseAudio?>(value: nil)
    fileprivate let sceneRelay = BehaviorRelay<SceneAudio?>(value: nil)
    fileprivate let audioRelay = BehaviorRelay<RecordingAudio?>(value: nil)
    fileprivate let audioType = BehaviorRelay<AudioType>(value: .none)
    fileprivate let timer = SceneTimer()
    fileprivate let disposeBag = DisposeBag()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    private var time: Driver<Int> {
        
        audioRelay.asDriver()
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest { $0.rx.currentTime }
    }
    
    private init() {
        
        timer.shouldSleep
            .withLatestFrom(sceneRelay.asDriver())
            .emit(onNext: {
                $0?.forcePause()
            })
            .disposed(by: disposeBag)
        
        let isSoundsEmpty = Driver
            .combineLatest(
                sceneRelay.asDriver(),
                audioRelay.asDriver()
            ) { $0 == nil && $1 == nil }
            .filter { $0 }
            .map { _ in AudioType.none }
        
        Driver<AudioType>
            .merge(
                isSoundsEmpty,
                isScenePlaying.filter { $0 }.map { _ in .scene },
                isPlaying.filter { $0 }.map { _ in .recording }
            )
            .distinctUntilChanged()
            .drive(audioType)
            .disposed(by: disposeBag)
        
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        setupRemoteTransportControls()
        
        let audioImage = audioRelay.asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map { value -> UIImage? in
                guard let value = value,
                    let url = value.recording.recording.imagePreviewUrl,
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                else {
                    return nil
                }
                
                return image
            }
        
        let sceneImage = sceneRelay.asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map { value -> UIImage? in
                guard let value = value,
                    let data = try? Data(contentsOf: value.scene.url),
                    let image = UIImage(data: data)
                else {
                    return nil
                }
                
                return image
            }
        
        Driver
            .combineLatest(
                sceneRelay.asDriver(),
                audioRelay.asDriver(),
                time,
                isPlaying,
                audioImage.startWith(nil)
                    .asDriver(onErrorJustReturn: nil)
                    .distinctUntilChanged(),
                sceneImage.startWith(nil)
                    .asDriver(onErrorJustReturn: nil)
                    .distinctUntilChanged(),
                audioType.asDriver()
            )
            .map { scene, audio, time, isPlaying, audioImage, sceneImage, type -> [String: Any] in
                
                guard type != .none else {
                    return [:]
                }
                
                let commandCenter = MPRemoteCommandCenter.shared()
                
                if scene != nil && type == .scene {
                    commandCenter.skipForwardCommand.isEnabled = false
                    commandCenter.skipBackwardCommand.isEnabled = false
                    
                    var nowPlayingInfo: [String: Any] = [
                        MPMediaItemPropertyTitle: "Scene"
                    ]
                    
                    if let image = sceneImage {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] =
                            MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    }
                    
                    return nowPlayingInfo
                }
                
                guard let audio = audio else {
                    return [:]
                }
                
                commandCenter.skipForwardCommand.isEnabled = true
                commandCenter.skipBackwardCommand.isEnabled = true
                
                var nowPlayingInfo: [String: Any] = [
                    MPMediaItemPropertyTitle: audio.recording.recording.name,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: time,
                    MPMediaItemPropertyPlaybackDuration: audio.recording.readingSound.soundSecs,
                    MPNowPlayingInfoPropertyPlaybackRate: isPlaying && time != 0 ? 1.0 : 0.0
                ]
                
                if let image = audioImage {
                    nowPlayingInfo[MPMediaItemPropertyArtwork] =
                        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                }
                
                return nowPlayingInfo
            }
            .drive(Binder(self) { base, info in
                base.nowPlayingInfoCenter.nowPlayingInfo = info
                if info.isEmpty {
                    base.audioRelay.value?.forcePause()
                    base.sceneRelay.value?.forcePause()
                    base.noiseRelay.value?.forcePause()
                    try? AVAudioSession.sharedInstance().setActive(
                        false,
                        options: .notifyOthersOnDeactivation
                    )
                } else {
                    try? AVAudioSession.sharedInstance().setActive(
                        true,
                        options: .notifyOthersOnDeactivation
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}

private extension AudioPlayerService {
    
    enum AudioType {
        case scene
        case recording
        case none
    }
}

private extension AudioPlayerService {
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand
            .addTarget { [weak self] _ in
                if let self = self,
                    self.audioType.value == .recording,
                    let audio = self.audioRelay.value,
                    !audio.isPlaying {
                    
                    self.noiseRelay.value?.forcePause()
                    audio.forcePlay()
                    return .success
                }
                if let self = self,
                    self.audioType.value == .scene,
                    let scene = self.sceneRelay.value,
                    !scene.isPlaying {
                    
                    self.noiseRelay.value?.forcePause()
                    scene.forcePlay()
                    return .success
                }
                return .commandFailed
            }

        commandCenter.pauseCommand
            .addTarget { [weak self] _ in
                if let self = self,
                    let audio = self.audioRelay.value,
                    audio.isPlaying {
                    
                    audio.forcePause()
                    return .success
                }
                if let self = self,
                    let scene = self.sceneRelay.value,
                    scene.isPlaying {
                    
                    scene.forcePause()
                    return .success
                }
                return .commandFailed
            }
        
        commandCenter.changePlaybackPositionCommand
            .addTarget { [weak self] event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent,
                    let audio = self?.audioRelay.value else {
                        return .commandFailed
                }
                audio.currentTime = CMTime(
                    seconds: round(event.positionTime),
                    preferredTimescale: 1
                )
                return .success
            }
        
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            guard let audio = self?.audioRelay.value else {
                return .commandFailed
            }
            audio.fastForward()
            return .success
        }
        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: 15)]
        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            guard let audio = self.audioRelay.value else {
                return .commandFailed
            }
            audio.rewind()
            return .success
        }
    }
}

extension Reactive where Base: AudioPlayerService {
    
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
    
    var resetAudio: Binder<Void> {

        Binder(base) { base, style in
            base.audioRelay.value?.reset()
        }
    }
    
    var sceneVolume: Binder<(to: Int, value: Float)> {
        
        Binder(base) { base, tuple in
            guard let scene = base.sceneRelay.value else {
                return
            }
            scene.setVolume(to: tuple.to, value: tuple.value)
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
    
    var noiseVolume: Binder<(to: Int, volume: Float)> {
        
        Binder(base) { base, tuple in
            base.noiseRelay.value?.setVolume(to: tuple.to, value: tuple.volume)
        }
    }
    
    var setTimer: Binder<Int> {
        
        Binder(base) { base, seconds in
            base.timer.start(with: seconds)
        }
    }
    
    var cancelTimer: Binder<Void> {
        
        Binder(base) { base, _ in
            base.timer.cancel()
        }
    }
}
