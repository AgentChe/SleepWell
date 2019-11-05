//
//  StoriesViewModel.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol StoriesViewModelInterface {
    func elements(subscription: Bool) -> Driver<[StoriesCellType]>
    func randomElement(items: [StoriesCellType]) -> Signal<StoriesCellType>
    func getStoryDetails(id: Int) -> Signal<StoryDetail?>
    func didTapCell(type: StoriesViewModel.Route)
}

final class StoriesViewModel: BindableViewModel {
    enum Route {
        case details(StoryDetail)
        case paygate
    }

    typealias Interface = StoriesViewModelInterface
    
    lazy var router: StoriesRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let storyService: StoryService
        let personalDataService: PersonalDataService
    }

    private let paygateResult = PublishRelay<PaygateCompletionResult>()
}

extension StoriesViewModel: StoriesViewModelInterface {
    
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
    
    func elements(subscription: Bool) -> Driver<[StoriesCellType]> {
        return Signal.combineLatest(isActiveSubscription(subscription: subscription), dependencies.storyService.stories().asSignal(onErrorJustReturn: []))
            .map { StoriesCellType.map(items: $1, isSubscription: $0) }
            .asDriver(onErrorJustReturn: [])
    }
    
    func randomElement(items: [StoriesCellType]) -> Signal<StoriesCellType> {
        let elemets = items.filter { type -> Bool in
            guard case .story = type else {
                return false
            }
            return true
        }
        
        guard let item = elemets.randomElement() else {
            return .empty()
        }
        
        return Signal.just(item)
    }

    func getStoryDetails(id: Int) -> Signal<StoryDetail?> {
        return dependencies.storyService
            .getStory(storyId: id)
            .asSignal(onErrorJustReturn: nil)
    }
    
    func didTapCell(type: StoriesViewModel.Route) {
        switch type {
        case let .details(detail):
            router.trigger(.details)
        case .paygate:
            router.trigger(.paygate({ [weak self] result in
                self?.paygateResult.accept(result)
                print(result)
            }))
        }
    }
   
}
