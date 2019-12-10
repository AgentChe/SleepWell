//
//  s.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 06/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import RxSwift
import Kingfisher

final class ImageCacheService {
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
    }()
    
    fileprivate func cacheImagesReactive(urls: [URL]) -> Single<Void>{
        return Single.create { single in
            let operations = urls.map { ImageFetchOperation(url: $0) }

            DispatchQueue.global().async { [weak self] in
                self?.queue.addOperations(operations, waitUntilFinished: true)

                DispatchQueue.main.async {
                    single(.success(Void()))
                }
            }

            return Disposables.create {
                for operation in operations {
                    operation.cancel()
                }
            }
        }
    }
}

extension ImageCacheService: ReactiveCompatible { }

extension Reactive where Base: ImageCacheService {
    func cacheImages(urls: [URL]) -> Single<Void> {
        return base.cacheImagesReactive(urls: urls)
    }
}

private final class ImageFetchOperation: Operation {
    private let url: URL
    
    private var task: DownloadTask?
    
    init(url: URL) {
        self.url = url
        
        super.init()
    }
    
    override var isAsynchronous: Bool { return true }
    override var isReady: Bool { return state == .ready && super.isReady }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
    
    @objc dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> { return ["state"] }
    @objc dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> { return ["state"] }
    @objc dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> { return ["state"] }
    @objc dynamic class func keyPathsForValuesAffectingIsCancelled() -> Set<String> { return ["state"] }
    
    private var rawState = State.ready
    
    private let stateQueue = DispatchQueue(label: "ImageFetchOperation.stateQueue.\(UUID().uuidString)", attributes: .concurrent)
    
    @objc private(set) dynamic var state: State {
        get {
            return stateQueue.sync { rawState }
        }
        set {
            stateQueue.sync(flags: .barrier) {
                self.rawState = newValue
            }
        }
    }
    
    @objc enum State: Int32 {
        case ready, executing, finished, cancelled
    }
    
    override func start() {
        guard !isCancelled else {
            state = .finished
            return
        }
        
        state = .executing
        
        task = KingfisherManager.shared.retrieveImage(with: url) { [weak self] _ in
            self?.state = .finished
        }
    }
    
    override func cancel() {
        super.cancel()
        
        task?.cancel()
        
        if state == .executing {
            state = .finished
        }
    }
}
