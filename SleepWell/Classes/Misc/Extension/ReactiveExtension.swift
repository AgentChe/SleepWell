//
//  ReactiveExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 01/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

extension Driver {
    
    public func reduce<A>(
        _ seed: A,
        accumulator: @escaping (A, Element) -> A
    ) -> SharedSequence<DriverSharingStrategy, A> {
        
        asObservable().reduce(seed, accumulator: accumulator)
            .asDriver(onErrorDriveWith: .empty())
    }
}

extension Observable {
    
    func retryWithDelay(
        interval: RxTimeInterval,
        repeat attempts: Int = .max
    ) -> Observable<Element> {
        retryWhen {
            $0.enumerated().flatMap  { index, error -> Observable<Int> in
                if index <= attempts {
                    return Observable<Int>
                        .timer(interval, scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                }
                return Observable<Int>.error(error)
            }
        }
    }
}
