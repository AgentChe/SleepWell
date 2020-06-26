//
//  BranchService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25.06.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Branch
import RxSwift

final class BranchService {
    static let shared = BranchService()
    
    private init() {}
}

// MARK: AppDelegate methods

extension BranchService {
    func application(didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) {
        Branch.getInstance().initSession(launchOptions: options)
        
        syncedUserId()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        Branch.getInstance().application(app, open: url, options: options)
    }
    
    func application(continue userActivity: NSUserActivity) {
        Branch.getInstance().continue(userActivity)
    }
    
    func application(didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        Branch.getInstance().handlePushNotification(userInfo)
    }
}

// MARK: Listening

extension BranchService {
    private func syncedUserId() {
        _ = Observable
            .merge(AppStateProxy.UserTokenProxy.didUpdatedUserToken.asObservable(),
                   AppStateProxy.UserTokenProxy.userTokenCheckedWithSuccessResult.asObservable())
            .subscribe(onNext: { properties in
                if let userId = SessionService.userId {
                    Branch.getInstance().setIdentity(String(userId))
                }
            })
    }
}

