//
//  VolumeViewModel.swift
//  SleepWell
//
//  Created by Alexander Mironov on 10/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol VolumeViewModelInterface {
    var currentMainPlayerVolume: Float? { get }
    var currentAmbientPlayerVolume: Float? { get }
    var mainPlayerVolume: Binder<Float> { get }
    var ambientPlayerVolume: Binder<Float> { get }
    func dismiss()
}

final class VolumeViewModel: BindableViewModel {
    typealias Interface = VolumeViewModelInterface
    
    lazy var router: VolumeRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let audioService: AudioPlayerService
    }
}

extension VolumeViewModel: VolumeViewModelInterface {
    
    var currentMainPlayerVolume: Float? {
        dependencies.audioService.currentMainPlayerVolume
    }
    
    var currentAmbientPlayerVolume: Float? {
        dependencies.audioService.currentAmbientPlayerVolume
    }
    
    var mainPlayerVolume: Binder<Float> {
        dependencies.audioService.rx.mainPlayerVolume
    }
    
    var ambientPlayerVolume: Binder<Float> {
        dependencies.audioService.rx.ambientPlayerVolume
    }
    
    func dismiss() {
        router.dismiss()
    }
}
