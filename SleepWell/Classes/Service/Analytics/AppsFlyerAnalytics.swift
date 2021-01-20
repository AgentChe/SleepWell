//
//  AppsFlyerAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20.01.2021.
//  Copyright © 2021 Andrey Chernyshev. All rights reserved.
//

import AppsFlyerLib
import RxSwift

final class AppsFlyerAnalytics {
    static let shared = AppsFlyerAnalytics()
    
    private let disposeBag = DisposeBag()
    
    private init() {}
}

// MARK: API
extension AppsFlyerAnalytics {
    func applicationDidFinishLaunchingWithOptions() {
        AppsFlyerLib.shared().appsFlyerDevKey = "AFxqJMmgWbp6GCahghVVH"
        AppsFlyerLib.shared().appleAppID = "1490113879"
    }
    
    func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
    }
    
    func logEvent(name: String, params: [String: Any] = [:]) {
        AppsFlyerLib.shared().logEvent(name, withValues: params)
    }
    
    func set(userId: String) {
        AppsFlyerLib.shared().customerUserID = userId
    }
    
    func getUID() -> String {
        AppsFlyerLib.shared().getAppsFlyerUID()
    }
}
