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
    func elements(selectedTag: Signal<Int>) -> Driver<[MeditateCellType]>
    func tags(selectedTag: Signal<Int>) -> Driver<[TagCellModel]>
    func didTapCell(model: MeditateCellType)
}

final class MeditateViewModel: BindableViewModel {
    typealias Interface = MeditateViewModelInterface
    
    lazy var router: MeditateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    struct Dependencies {}
    
    let test: [Meditation] = [
        ]
}

extension MeditateViewModel: MeditateViewModelInterface {
    private func isActiveSubscription() -> Observable<Bool> {
        return .just(false)
    }

    func elements(selectedTag: Signal<Int>) -> Driver<[MeditateCellType]> {
        let elements = Observable.combineLatest(
        Observable<[Meditation]>.just(test),
        isActiveSubscription())
        return selectedTag
            .asObservable()
            .map { $0 }
            .startWith(nil)
            .withLatestFrom(elements) { ($0, $1) }
            .map { id, args -> [MeditateCellType] in
                let (elements, isActiveSubscription) = args
                guard let id = id else {
                    return MeditateCellType.map(items: elements, isSubscription: isActiveSubscription)
                }
                return MeditateCellType.map(
                    items: elements.filter { $0.tags.contains(id) },
                    isSubscription: isActiveSubscription
                )
            }
        .asDriver(onErrorJustReturn: [])
    }
    
    func tags(selectedTag: Signal<Int>) -> Driver<[TagCellModel]> {
        let elements = Observable<[MeditationTag]>.just([
            MeditationTag(id: 1, name: "All"),
            MeditationTag(id: 2, name: "Sleep"),
            MeditationTag(id: 3, name: "Anxiety"),
            MeditationTag(id: 4, name: "Beginners")])
        return selectedTag
            .asObservable()
            .map { $0 }
            .startWith(nil)
            .withLatestFrom(elements) { TagCellModel.map(items: $1, selectedId: $0) }
            .asDriver(onErrorJustReturn: [])
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
