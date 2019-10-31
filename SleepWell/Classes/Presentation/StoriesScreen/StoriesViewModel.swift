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
    func elements() -> Driver<[StoriesCellType]>
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
    }

    let storyLoading = RxActivityIndicator()
}

extension StoriesViewModel: StoriesViewModelInterface {
    
    private func isActiveSubscription() -> Observable<Bool> {
        return .just(true)
    }
    
    func elements() -> Driver<[StoriesCellType]> {
        return Observable.combineLatest(isActiveSubscription(), dependencies.storyService.stories().asObservable())
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
            .trackActivity(storyLoading)
            .asSignal(onErrorJustReturn: nil)
    }
    
    func didTapCell(type: StoriesViewModel.Route) {
        switch type {
        case let .details(detail):
            router.trigger(.details)
        case .paygate:
            router.trigger(.paygate)
        }
    }
   
}
