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
