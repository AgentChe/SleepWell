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
}

final class SoundsViewModel: BindableViewModel {
    typealias Interface = SoundsViewModelInterface
    
    lazy var router: SoundsRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let noiseService: NoiseService
        let audioPlayerService: AudioPlayerService
    }
}

extension SoundsViewModel: SoundsViewModelInterface {
    
    func sounds() -> Driver<[NoiseCategory]> {
        return dependencies.noiseService
            .noiseCategories()
            .asDriver(onErrorJustReturn: [])
    }
    
    func add(noises: Set<NoiseSound>) -> Completable {
        dependencies.audioPlayerService.add(noises: noises)
    }
    
    var noiseVolume: Binder<(to: Int, volume: Float)> {
        dependencies.audioPlayerService.rx.noiseVolume
    }
}
