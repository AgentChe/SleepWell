//
//  ScenesViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol ScenesViewModelInterface {
    func elements(subscription: Observable<Bool>) -> Driver<[SceneCellModel]>
    func sceneDetails(id: Int) -> Signal<ScenesViewModel.Action?>
}

final class ScenesViewModel: BindableViewModel {
    enum Action {
        case paygate
        case detail(SceneDetail?)
    }
    
    typealias Interface = ScenesViewModelInterface
    
    lazy var router: ScenesRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let sceneService: SceneService
    }
}

extension ScenesViewModel: ScenesViewModelInterface {
    
    func elements(subscription: Observable<Bool>) -> Driver<[SceneCellModel]> {
        let scenes = dependencies.sceneService
            .scenes()
            .asDriver(onErrorJustReturn: [])
        
        return Driver
            .combineLatest(
                scenes,
                subscription.asDriver(onErrorJustReturn: false)
            )
            .map { SceneCellModel.map(scene: $0.0, isActiveSubscription: $0.1) }
    }

    func sceneDetails(id: Int) -> Signal<Action?> {
        return dependencies.sceneService
            .getScene(by: id)
            .map { Action.detail($0) }
            .catchError { error -> Single<Action?> in
                guard (error as NSError).code == 403  else {
                    return .never()
                }
                return .just(.paygate)
            }
            .asSignal(onErrorJustReturn: nil)
    }
}
