//
//  PlayerViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol PlayerViewModelInterface {
    var setTime: Binder<Int> { get }
    func playRecording(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void>
    var isPlaying: Driver<Bool> { get }
    func time(for id: Int) -> Driver<Int>
    func isPlaying(recording: RecordingDetail) -> Driver<Bool>
    func add(recording: RecordingDetail) -> Signal<Void>
    func goToVolumeScreen(recording: RecordingDetail)
    var resetAudio: Binder<Void> { get }
    func pauseNoise() -> Signal<Void>
}

final class PlayerViewModel: BindableViewModel {
    typealias Interface = PlayerViewModelInterface
    
    lazy var router: PlayerRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioService: AudioPlayerService
    }
}

extension PlayerViewModel: PlayerViewModelInterface {
    
    var setTime: Binder<Int> {
        dependencies.audioService.rx.setTime
    }
    
    func playRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.playRecording(style: style)
    }
    
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.pauseRecording(style: style)
    }
    
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioService.pauseScene(style: style)
    }
    
    func time(for id: Int) -> Driver<Int> {
        dependencies.audioService.time(for: id)
    }
    
    var isPlaying: Driver<Bool> {
        dependencies.audioService.isPlaying
    }
    
    func isPlaying(recording: RecordingDetail) -> Driver<Bool> {
        dependencies.audioService.isPlaying(recording: recording)
    }
    
    func add(recording: RecordingDetail) -> Signal<Void> {
        dependencies.audioService.add(recording: recording)
    }
    
    func goToVolumeScreen(recording: RecordingDetail) {
        router.goToVolumeScreen(recording: recording)
    }
    
    var resetAudio: Binder<Void> {
        dependencies.audioService.rx.resetAudio
    }
    
    func pauseNoise() -> Signal<Void> {
        dependencies.audioService.pauseNoise()
    }
}
