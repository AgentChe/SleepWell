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
    private let queue = OperationQueue()
    
    init(maxConcurrentRequests: Int = 5, qos: QualityOfService = .default) {
        queue.qualityOfService = qos
        queue.maxConcurrentOperationCount = maxConcurrentRequests
    }
    
    fileprivate func cacheImagesReactive(urls: [URL]) -> Single<Void>{
        return Single.create { single in
            let observableQueue = DispatchQueue(label: "ImageCacheService.observableQueue")
            
            let operations = urls.map { ImageFetchOperation(url: $0) }
            
            DispatchQueue.global().async { [weak self] in
                self?.queue.addOperations(operations, waitUntilFinished: true)
                
                observableQueue.async {
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
    typealias CompletionHandler = (ImageFetchOperation, UIImage?, Error?) -> Void
    
    private let url: URL
    private let completionHandler: CompletionHandler?
    
    private var task: DownloadTask?
    
    init(url: URL, completionHandler: CompletionHandler? = nil) {
        self.url = url
        self.completionHandler = completionHandler
        
        super.init()
        
        self.name = "ImageFetchOperation(\"\(url.absoluteString)\")"
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
    
    private let stateQueue = DispatchQueue(label: "ImageFetchOperation.stateQueue", attributes: .concurrent)
    
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
        
        task = KingfisherManager.shared.retrieveImage(with: url) { [weak self] completion in
            switch completion {
            case .success(let result):
                self?.onSuccess(result.image)
            case .failure(let error):
                self?.onError(error)
            }
        }
    }
    
    override func cancel() {
        super.cancel()
        
        task?.cancel()
        task = nil
        
        if state == .executing {
            state = .finished
        }
    }
    
    private func onError(_ error: Error?) {
        state = .finished
        task = nil
        completionHandler?(self, nil, error)
    }
    
    private func onSuccess(_ image: UIImage) {
        state = .finished
        task = nil
        completionHandler?(self, image, nil)
    }
}
