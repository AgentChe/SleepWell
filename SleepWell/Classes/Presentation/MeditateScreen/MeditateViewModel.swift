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
    func elements(subscription: Bool, selectedTag: Signal<Int?>) -> Driver<[MeditateCellType]>
    func tags(selectedTag: Signal<Int?>) -> Driver<[TagCellModel]>
    func getMeditationDetails(meditationId: Int) -> Signal<MeditationDetail?>
    func didTapCell(model: MeditateCellType)
}

final class MeditateViewModel: BindableViewModel {
    enum Route {
        case details(MeditationDetail)
        case paygate
    }

    typealias Interface = MeditateViewModelInterface
    
    lazy var router: MeditateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()

    struct Dependencies {
        let meditatationService: MeditationService
        let personalDataService: PersonalDataService
    }
    
    private let paygateResult = PublishRelay<PaygateCompletionResult>()
}

extension MeditateViewModel: MeditateViewModelInterface {    
    private func isActiveSubscription(subscription: Bool) -> Signal<Bool> {
        let isActiveSubscription = Signal.just(subscription)
        let result = paygateResult
            .asSignal()
            .flatMapLatest { [weak self] paygateResult -> Signal<Bool> in
                guard let this = self else {
                    return .never()
                }
                switch paygateResult {
                case .purchased, .restored:
                    return this.dependencies.personalDataService
                        .sendPersonalData()
                        .map { true }
                        .asSignal(onErrorSignalWith: .never())
                case .closed:
                    return .just(false)
                }
            }
        return Signal.merge(isActiveSubscription, result)
    }

    func elements(subscription: Bool, selectedTag: Signal<Int?>) -> Driver<[MeditateCellType]> {
        let meditations = dependencies.meditatationService.meditations().asSignal(onErrorJustReturn: [])
        let isActive = isActiveSubscription(subscription: subscription)
        return Signal.combineLatest(selectedTag, meditations, isActive)
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
        let tags = dependencies.meditatationService.getTags()
        return Observable
            .combineLatest(selectedTag.asObservable(), tags.asObservable())
            .map { TagCellModel.map(items: $1, selectedId: $0) }
            .asDriver(onErrorJustReturn: [])
    }
    
    func getMeditationDetails(meditationId: Int) -> Signal<MeditationDetail?> {
        return dependencies.meditatationService
            .getMeditation(meditationId: meditationId)
            .asSignal(onErrorJustReturn: nil)
    }
    
    func didTapCell(model: MeditateCellType) {
        switch model {
        case let .meditate(element):
            print("meditate")
        case .premiumUnlock:
            print("premiumUnlock")
        }
    }
}
