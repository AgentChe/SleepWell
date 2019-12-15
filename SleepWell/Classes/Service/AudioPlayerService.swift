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
        audio.prepareToPlay()
    }
    
    func add(recording: RecordingDetail) -> Signal<Void> {
        
        guard recording.recording.id != audioRelay.value?.recording.recording.id else {
            return .just(())
        }

        return .deferred { [weak self] in
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
        sceneAudio.prepareToPlay()
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
    
    fileprivate let sceneRelay = BehaviorRelay<SceneAudio?>(value: nil)
    fileprivate let audioRelay = BehaviorRelay<Audio?>(value: nil)
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
                    
                    audio.forcePlay()
                    return .success
                }
                if let self = self,
                    self.audioType.value == .scene,
                    let scene = self.sceneRelay.value,
                    !scene.isPlaying {
                    
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

private final class SceneTimer {
    
    func start(with seconds: Int) {
        disposeBag = DisposeBag()
        
        let timer = Driver<Int>.timer(.seconds(0), period: .seconds(1))
            .map { seconds - $0 }
            .take(seconds + 1)
        
        timer.drive(_currentSeconds)
            .disposed(by: disposeBag)
        
        timer.filter { $0 == 0 }
            .take(1)
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: _shouldSleep)
            .disposed(by: disposeBag)
    }
    
    func cancel() {
        disposeBag = DisposeBag()
        _currentSeconds.accept(0)
    }
    
    var isRunning: Driver<Bool> {
        
        _currentSeconds.asDriver()
            .map { $0 != 0 }
            .distinctUntilChanged()
    }
    
    var currentSeconds: Driver<Int> {
        _currentSeconds.asDriver()
    }
    
    var shouldSleep: Signal<Void> {
        _shouldSleep.asSignal()
    }
    
    private let _currentSeconds = BehaviorRelay<Int>(value: 0)
    private let _shouldSleep = PublishRelay<Void>()
    private var disposeBag = DisposeBag()
}

private final class SceneAudio: ReactiveCompatible {
    
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
            $0.player.volume = 0.75
        }
        let volumes = players.reduce([Int: Float]()) { result, player in
            var result = result
            result[player.id] = 0.75
            return result
        }
        _currentScenePlayersVolume.accept(volumes)
        prepareRetry()
    }
    
    func prepareRetry() {
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
    
    func play(style: PlayAndPauseStyle) -> Signal<Void> {
        switch style {
        case .force:
            return .deferred { [weak self] in
                self?.forcePlay()
                return .just(())
            }
        case .gentle:
            let initialVolumes = players.map { $0.player.volume }
            players.forEach { $0.player.volume = 0 }
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
                    guard let scene = self else {
                        return
                    }
                    scene.players.enumerated()
                        .forEach { index, player in
                            guard let initialVolume = initialVolumes.item(at: index) else {
                                return
                            }
                            player.player.volume = progress * initialVolume
                        }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func pause(style: PlayAndPauseStyle) -> Signal<Void> {
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
            
            let initialVolumes = players.map { $0.player.volume }
            return Observable<Int>
                .timer(
                    .milliseconds(0),
                    period: .milliseconds(10),
                    scheduler: MainScheduler.instance
                )
                .take(101)
                .map { 1.0 - Float($0) / 100.0 }
                .do(onNext: { [weak self] progress in
                    guard let scene = self else {
                        return
                    }
                    scene.players.enumerated()
                        .forEach { index, player in
                            guard let initialVolume = initialVolumes.item(at: index) else {
                                return
                            }
                            player.player.volume = progress * initialVolume
                        }
                    
                    if progress == 0.0 {
                        scene.forcePause()
                        
                        scene.players.enumerated()
                            .forEach { index, player in
                                guard let initialVolume = initialVolumes.item(at: index) else {
                                    return
                                }
                                player.player.volume = initialVolume
                            }
                    }
                })
                .takeLast(1)
                .map { _ in () }
                .asSignal(onErrorSignalWith: .empty())
        }
    }
    
    func setVolume(to id: Int, value: Float) {
        guard value >= 0.0 && value <= 1.0 else {
            return
        }
        if let player = players.first(where: { $0.id == id }) {
            player.player.volume = value
            var newVolumes = _currentScenePlayersVolume.value
            newVolumes[id] = value
            _currentScenePlayersVolume.accept(newVolumes)
        }
    }
    
    var isPlaying: Bool {
        guard let player = players.first?.player else {
            return false
        }
        return player.rate != 0 && player.error == nil
    }
    
    func forcePause() {
        players.forEach {
            $0.player.pause()
        }
    }
    
    func forcePlay() {
        players.forEach {
            $0.player.play()
        }
    }
    
    var currentScenePlayersVolume: [Int: Float] {
        _currentScenePlayersVolume.value
    }
    
    private let _currentScenePlayersVolume = BehaviorRelay<[Int: Float]>(value: [:])
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
    
    private let _mainPlayerVolume = BehaviorRelay<Float>(value: 0.75)
    private let _ambientPlayerVolume = BehaviorRelay<Float>(value: 0.75)
    private let isPausing = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
}

private extension Audio {
    
    var isPlaying: Bool {
        mainPlayer.rate == 1
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

private extension Reactive where Base: Audio {
    
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

private extension Reactive where Base: SceneAudio {
    
    var isPlaying: Driver<Bool> {
        
        Driver<Int>.timer(.milliseconds(0), period: .milliseconds(100))
            .map { [base] _ in
                base.isPlaying
            }
            .distinctUntilChanged()
    }
}

private extension Array {
    
    func item(at index: Int) -> Element? {
        guard index >= 0 && index < count else {
            return nil
        }
        return self[index]
    }
}
