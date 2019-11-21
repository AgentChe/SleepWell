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

final class AudioPlayerService: ReactiveCompatible {
    
    static let shared = AudioPlayerService()
    
    func add(recording: RecordingDetail) {
        
        guard recording.recording.id != audioRelay.value?.recording.recording.id else {
            return
        }
        
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
        audioRelay.accept(audio)
        sceneRelay.accept(nil)
        audio.prepareToPlay()
    }
    
    func add(sceneDetail: SceneDetail) {
        
        guard sceneDetail.scene.id != sceneRelay.value?.scene.id
            && !sceneDetail.sounds.isEmpty else {
            return
        }
        
        let players = sceneDetail.sounds
            .map {
                SceneAudio.Player(
                    player: AVPlayer(url: $0.soundUrl),
                    id: $0.id
                )
            }
        
        let sceneAudio = SceneAudio(
            players: players,
            scene: sceneDetail.scene
        )
        sceneRelay.accept(sceneAudio)
        audioRelay.accept(nil)
        sceneAudio.prepareToPlay()
    }
    
    func isPlaying(recording: RecordingDetail) -> Bool {
        
        audioRelay.value?.recording.recording.id == recording.recording.id
    }
    
    var time: Driver<Int> {
        
        audioRelay.asDriver()
            .filter { $0 != nil }
            .map { $0! }
            .flatMapLatest { $0.rx.currentTime }
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
    
    var currentScenePlayersVolume: [(id: Int, value: Float)]? {
        sceneRelay.value?.players.map { ($0.id, $0.player.volume) }
    }
    
    fileprivate let sceneRelay = BehaviorRelay<SceneAudio?>(value: nil)
    fileprivate let audioRelay = BehaviorRelay<Audio?>(value: nil)
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let disposeBag = DisposeBag()
    
    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        setupRemoteTransportControls()
        
        let audioImage = audioRelay.asObservable()
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
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        
        let sceneImage = sceneRelay.asObservable()
            .map { value -> UIImage? in
                guard let value = value,
                    let url = value.scene.imageUrl,
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                else {
                    return nil
                }
                
                return image
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        
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
                    .distinctUntilChanged()
            )
            .map { scene, audio, time, isPlaying, audioImage, sceneImage -> [String: Any] in
                
                let commandCenter = MPRemoteCommandCenter.shared()
                
                guard scene == nil else {
                    commandCenter.skipForwardCommand.isEnabled = false
                    commandCenter.skipBackwardCommand.isEnabled = false
                    
                    var nowPlayingInfo: [String: Any] = [
                        MPMediaItemPropertyTitle: "Scene"
                    ]
                    
                    if let image = audioImage {
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
                    base.audioRelay.value?.pause()
                    try? AVAudioSession.sharedInstance().setActive(
                        false,
                        options: .notifyOthersOnDeactivation
                    )
                } else {
                    try? AVAudioSession.sharedInstance().setActive(
                        false,
                        options: .notifyOthersOnDeactivation
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}

private extension AudioPlayerService {
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand
            .addTarget { [weak self] _ in
                if self?.audioRelay.value?.isPlaying == false {
                    self?.audioRelay.value?.play()
                    return .success
                }
                return .commandFailed
            }

        commandCenter.pauseCommand
            .addTarget { [weak self] _ in
                if self?.audioRelay.value?.isPlaying == true {
                    self?.audioRelay.value?.pause()
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

private final class SceneAudio {
    
    struct Player {
        let player: AVPlayer
        let id: Int
    }
    
    let players: [Player]
    let scene: Scene
    
    init(players: [Player], scene: Scene) {
        self.players = players
        self.scene = scene
    }
    
    func prepareToPlay() {
        
        players.forEach {
            NotificationCenter.default.rx
            .notification(
                .AVPlayerItemDidPlayToEndTime,
                object: $0.player
            )
            .bind(to: Binder($0.player) { player, _ in
                player.seek(to: CMTime.zero)
                player.play()
            })
            .disposed(by: disposeBag)
        }
    }
    
    func play() {
        players.forEach {
            $0.player.play()
        }
    }
    
    func pause() {
        players.forEach {
            $0.player.pause()
        }
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        players.first(where: { $0.id == id })?.player.volume = value
    }
    
    private let disposeBag = DisposeBag()
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
    
    private let disposeBag = DisposeBag()
}

private extension Audio {
    
    var isPlaying: Bool {
        mainPlayer.rate == 1
    }
}

extension Reactive where Base: AudioPlayerService {
    
    var play: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.play()
        }
    }
    
    var playScene: Binder<Void> {
        
        Binder(base) { base, _ in
            base.sceneRelay.value?.play()
        }
    }
    
    var pause: Binder<Void> {
        
        Binder(base) { base, _ in
            base.audioRelay.value?.pause()
        }
    }
    
    var pauseScene: Binder<Void> {
        
        Binder(base) { base, _ in
            base.sceneRelay.value?.pause()
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
