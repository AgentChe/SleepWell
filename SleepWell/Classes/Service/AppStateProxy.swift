//
//  AppStateProxy.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxCocoa

final class AppStateProxy {
    struct PushNotificationsProxy {
        static var notifyAboutPushTokenHasArrived: (() -> Void)?
        static let notifyAboutPushMessageArrived = PublishRelay<[AnyHashable : Any]>()
    }
    
    struct ApplicationProxy {
        static let didBecomeActive = PublishRelay<Void>()
    }
}
