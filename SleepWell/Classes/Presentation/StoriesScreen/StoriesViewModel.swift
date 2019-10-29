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
    func selectedElement(item: StoriesCellType)
}

final class StoriesViewModel: BindableViewModel {
    typealias Interface = StoriesViewModelInterface
    
    lazy var router: StoriesRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
    
    let mock: [Story] = [Story(id: 1, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 10000),
    Story(id: 1, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 521),
    Story(id: 2, name: "The Power of Gratitude", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 789),
    Story(id: 3, name: "Honor Emotions", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 753621),
    Story(id: 4, name: "Anxiety Meditation", paid: true, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 752841),
    Story(id: 5, name: "Honor Emotions", paid: false, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 22222),
    Story(id: 6, name: "Anxiety Meditation", paid: false, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 100000),
    Story(id: 7, name: "Honor Emotions", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 100),
    Story(id: 8, name: "Anxiety Meditation", paid: false, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 190000),
    Story(id: 9, name: "Honor Emotions", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 23510),
    Story(id: 10, name: "Honor Emotions", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 1230),
    Story(id: 11, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", length_sec: 100000), ]
}

extension StoriesViewModel: StoriesViewModelInterface {
    private func isActiveSubscription() -> Observable<Bool> {
        return .just(false)
    }
    
    func elements() -> Driver<[StoriesCellType]> {
        return Observable
            .combineLatest(Observable.just(mock), isActiveSubscription())
            .map { StoriesCellType.map(items: $0, isSubscription: $1) }
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
    
    func selectedElement(item: StoriesCellType) {
        switch item {
        case let .story(story):
            print("story")
        case .premiumUnlock:
            print("premiumUnlock")
        }
    }
}
