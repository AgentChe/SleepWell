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
        Meditation(id: 1, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1]),
        Meditation(id: 2, name: "Honor Emotions", paid: false, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1]),
        Meditation(id: 3, name: "Honor Emotions", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1]),
        Meditation(id: 4, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1]),
        Meditation(id: 5, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 6, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 7, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [3]),
        Meditation(id: 8, name: "Anxiety Meditation", paid: false, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 9, name: "Honor Emotions", paid: false, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 3, 4]),
        Meditation(id: 10, name: "Anxiety Meditation", paid: false, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2, 3, 4]),
        Meditation(id: 11, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2, 3]),
        Meditation(id: 12, name: "Anxiety Meditation", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [3]),
        Meditation(id: 13, name: "Honor Emotions", paid: true, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [2]),
        Meditation(id: 14, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [2]),
        Meditation(id: 15, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [2]),
        Meditation(id: 16, name: "Honor Emotions", paid: true, reader: "Elizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [3]),
        Meditation(id: 17, name: "Anxiety Meditation", paid: false, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 18, name: "The Power of Gratitude", paid: false, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 4]),
        Meditation(id: 19, name: "Anxiety Meditation", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 20, name: "Honor Emotions", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 21, name: "Anxiety Meditation", paid: false, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 3]),
        Meditation(id: 22, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [4, 2]),
        Meditation(id: 23, name: "Anxiety Meditation", paid: true, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 2]),
        Meditation(id: 24, name: "The Power of Gratitude", paid: true, reader: "Mil Nicholson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [3, 2]),
        Meditation(id: 25, name: "Anxiety Meditation", paid: true, reader: "SElizabeth Klett", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [1, 4]),
        Meditation(id: 26, name: "Honor Emotions", paid: false, reader: "Jina Anderson", imagePreviewUrl: nil, imageReaderURL: nil, hash: "", tags: [4])]
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
