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
        static let didEnterBackground = PublishRelay<Void>()
        static let didBecomeActive = PublishRelay<Void>()
        static let completeTransactions = PublishRelay<Void>()
    }
    
    struct NavigateProxy {
        static let openPaygateAtPromotionInApp = PublishRelay<Void>()
    }
    
    struct UserTokenProxy {
        static let didUpdatedUserToken = PublishRelay<Void>()
        static let userTokenCheckedWithSuccessResult = PublishRelay<Void>()
    }
}
