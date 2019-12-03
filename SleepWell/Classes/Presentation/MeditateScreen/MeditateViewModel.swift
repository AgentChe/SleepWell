//
//  MeditateViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol MeditateViewModelInterface {
    func elements(subscription: Observable<Bool>, selectedTag: Signal<Int?>) -> Driver<[MeditateCellType]>
    func tags(selectedTag: Signal<Int?>) -> Driver<[TagCellModel]>
    func getMeditationDetails(meditationId: Int) -> Signal<MeditateViewModel.Action>
}

final class MeditateViewModel: BindableViewModel {

    enum Action {
        case paygate
        case detail(MeditationDetail?)
    }

    typealias Interface = MeditateViewModelInterface
    
    lazy var router: MeditateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()

    struct Dependencies {
        let meditatationService: MeditationService
    }
    
    private let paygateResult = PublishRelay<PaygateCompletionResult>()
}

extension MeditateViewModel: MeditateViewModelInterface {
    func elements(subscription: Observable<Bool>, selectedTag: Signal<Int?>) -> Driver<[MeditateCellType]> {
        let meditations = dependencies
            .meditatationService
            .meditations()
            .asSignal(onErrorJustReturn: [])

        return Signal
            .combineLatest(
                selectedTag,
                meditations,
                subscription.asSignal(onErrorJustReturn: false)
            )
            .map { tag, elements, isActiveSubscription -> [MeditateCellType] in
                guard let id = tag else {
                    return MeditateCellType.map(items: elements, isSubscription: isActiveSubscription)
                }
                return MeditateCellType.map(
                    items: elements.filter { $0.tags.contains(id) },
                    isSubscription: isActiveSubscription
                )
            }
            .asDriver(onErrorJustReturn: [])
    }
    
    func tags(selectedTag: Signal<Int?>) -> Driver<[TagCellModel]> {
        let tags = dependencies.meditatationService.tags()
        return Observable
            .combineLatest(selectedTag.asObservable(), tags.asObservable())
            .map { TagCellModel.map(items: $1, selectedId: $0) }
            .asDriver(onErrorJustReturn: [])
    }
    
    func getMeditationDetails(meditationId: Int) -> Signal<Action> {
        return dependencies.meditatationService
            .meditation(meditationId: meditationId)
            .map { Action.detail($0) }
            .catchError { error -> Single<Action> in
                guard (error as NSError).code == 403  else {
                    return .never()
                }
                return .just(.paygate)
            }
            .asSignal(onErrorSignalWith: .empty())
    }
}
