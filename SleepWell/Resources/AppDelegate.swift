//
//  AppDelegate.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PurchaseService.register()
        PushMessagesService.shared.configure()
        FirebaseApp.configure()
        RateManager.incrementRun()
        
        navigate()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppStateProxy.PushNotificationsProxy.notifyAboutPushTokenHasArrived?()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AppStateProxy.PushNotificationsProxy.notifyAboutPushMessageArrived.accept(userInfo)

        completionHandler(.noData)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppStateProxy.ApplicationProxy.didBecomeActive.accept(Void())
    }
    
    private var router: Router?
    private func navigate() {
        _ = AppStateProxy.NavigateProxy.openPaygateAtPromotionInApp
            .subscribe(onNext: {
                if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                    self.router = Router(transitionHandler: rootVC)
                    self.router?.present(type: PaygateAssembly.self, input: PaygateViewController.Input(openedFrom: .promotionInApp, completion: nil))
                }
            })
    }
}
