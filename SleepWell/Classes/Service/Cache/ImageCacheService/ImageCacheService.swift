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

final class DownloadImagesService {
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func downloadImages(urls: [URL]) -> Single<Void>{
        return Single.create { single in
            let operations = urls.map { DownloadRemoteImageOperation(url: $0) }

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

final class CopyImagesService {
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func copyImages(copingLocalImages: [CopyResource]) -> Single<Void> {
        return Single.create { single in
            let operations = copingLocalImages.map { CopyInCacheLocalImageOperation(copingLocalImage: $0) }
            
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
    
    func backgroundCopyImages(copingLocalImages: [CopyResource]) {
        let operations = copingLocalImages.map { CopyInCacheLocalImageOperation(copingLocalImage: $0) }
        queue.addOperations(operations, waitUntilFinished: false)
    }
}
