//
//  SoundsViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright (c) 2020 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol SoundsViewModelInterface {
    func sounds() -> Driver<[NoiseCategory]>
    func add(noises: Set<NoiseSound>) -> Completable
    var noiseVolume: Binder<(to: Int, volume: Float)> { get }
    func copy(url: [URL]) -> Signal<Void>
    var playNoise: Binder<Void> { get }
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void>
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void>
}

final class SoundsViewModel: BindableViewModel {
    typealias Interface = SoundsViewModelInterface
    
    lazy var router: SoundsRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let noiseService: NoiseService
        let audioPlayerService: AudioPlayerService
        let mediaCacheService: MediaCacheService
    }
}

extension SoundsViewModel: SoundsViewModelInterface {
    
    func sounds() -> Driver<[NoiseCategory]> {
        return dependencies.noiseService
            .noiseCategories()
            .map { $0.sorted(by: { $0.sort < $1.sort }) }
            .asDriver(onErrorJustReturn: [])
    }
    
    func add(noises: Set<NoiseSound>) -> Completable {
        dependencies.audioPlayerService.add(noises: noises)
    }
    
    var noiseVolume: Binder<(to: Int, volume: Float)> {
        dependencies.audioPlayerService.rx.noiseVolume
    }
    
    func copy(url: [URL]) -> Signal<Void> {
        dependencies.mediaCacheService.copy(urls: url)
            .asSignal(onErrorSignalWith: .empty())
    }
    
    var playNoise: Binder<Void> {
        dependencies.audioPlayerService.rx.playNoise
    }
    
    func pauseScene(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioPlayerService.pauseScene(style: style)
    }
    
    func pauseRecording(style: PlayAndPauseStyle) -> Signal<Void> {
        dependencies.audioPlayerService.pauseRecording(style: style)
    }
}
