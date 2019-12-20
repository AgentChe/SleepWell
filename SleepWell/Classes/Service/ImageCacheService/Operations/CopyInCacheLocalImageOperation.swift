//
//  CopyInCacheLocalImageOperation.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 21/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation
import Kingfisher

struct CopingLocalImage {
    let imageName: String
    let imageCacheKey: String
}

final class CopyInCacheLocalImageOperation: Operation {
    private let copingLocalImage: CopingLocalImage
    
    init(copingLocalImage: CopingLocalImage) {
        self.copingLocalImage = copingLocalImage
        
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
    
    private let stateQueue = DispatchQueue(label: "CopyInCacheLocalImageOperation.stateQueue.\(UUID().uuidString)", attributes: .concurrent)
    
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
        
        guard let image = UIImage(named: copingLocalImage.imageName) else {
            state = .finished
            return
        }
        
        ImageCache.default.store(image, forKey: copingLocalImage.imageCacheKey) { [weak self] _ in
            self?.state = .finished
        }
    }
    
    override func cancel() {
        super.cancel()
        
        if state == .executing {
            state = .finished
        }
    }
}
