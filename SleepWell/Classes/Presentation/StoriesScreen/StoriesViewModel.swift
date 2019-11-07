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
    func elements(subscription: Observable<Bool>) -> Driver<[StoriesCellType]>
    func randomElement(items: [StoriesCellType]) -> Signal<StoriesCellType>
    func getStoryDetails(id: Int) -> Signal<StoryDetail?>
}

final class StoriesViewModel: BindableViewModel {

    typealias Interface = StoriesViewModelInterface
    
    lazy var router: StoriesRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let storyService: StoryService
    }

    private let paygateResult = PublishRelay<PaygateCompletionResult>()
}

extension StoriesViewModel: StoriesViewModelInterface {
    func elements(subscription: Observable<Bool>) -> Driver<[StoriesCellType]> {
        return Signal
            .combineLatest(
                subscription.asSignal(onErrorJustReturn: false),
                dependencies.storyService.stories().asSignal(onErrorJustReturn: []))
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
}
