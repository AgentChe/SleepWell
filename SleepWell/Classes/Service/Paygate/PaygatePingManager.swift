//
//  PaygatePingManager.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 11.07.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class PaygatePingManager {
    static let shared = PaygatePingManager()
    
    private var disposable: Disposable?
    
    private init() {
        _ = AppStateProxy
            .ApplicationProxy
            .didEnterBackground
            .subscribe(onNext: {
                self.stop()
            })
    }
    
    func start() {
        disposable = ping()
            .subscribe()
    }
    
    func stop() {
        disposable?.dispose()
    }
}

// MARK: Private

private extension PaygatePingManager {
    func ping() -> Observable<Void> {
        Observable<Int>
            .interval(RxTimeInterval.seconds(2), scheduler: SerialDispatchQueueScheduler.init(qos: .background))
            .flatMapLatest { _ in
                SDKStorage.shared
                    .restApiTransport
                    .callServerApi(requestBody: PaygatePingRequest(randomKey: SDKStorage.shared.applicationAnonymousID))
                    .map { _ in Void() }
                    .catchError { _ in .never() }
            }
    }
}
