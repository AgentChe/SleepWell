//
//  SharedSequenceExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 11/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

extension SharedSequence {
    
    func take(_ count: Int) -> SharedSequence<SharingStrategy, Element> {
        return asObservable().take(count).asSharedSequence(
            sharingStrategy: SharingStrategy.self,
            onErrorDriveWith: SharedSequence<SharingStrategy, Element>.empty()
        )
    }
}
