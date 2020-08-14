//
//  AppDelegate.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PurchaseService.register()
        PushMessagesService.shared.configure()
        FirebaseApp.configure()
        RateManager.incrementRun()
        AmplitudeAnalytics.shared.configure()
        FacebookAnalytics.shared.configure()
        IDFAService.shared.configure()
        BranchService.shared.application(didFinishLaunchingWithOptions: launchOptions)
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        navigate()
        
        PushMessagesService.shared.updateLocalNotification()

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        BranchService.shared.application(app, open: url, options: options)
        ApplicationDelegate.shared.application(app, open: url, options: options)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppStateProxy.PushNotificationsProxy.notifyAboutPushTokenHasArrived?()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        BranchService.shared.application(didReceiveRemoteNotification: userInfo)
        AppStateProxy.PushNotificationsProxy.notifyAboutPushMessageArrived.accept(userInfo)

        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        BranchService.shared.application(continue: userActivity)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppStateProxy.ApplicationProxy.didBecomeActive.accept(Void())
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AppStateProxy.ApplicationProxy.didEnterBackground.accept(Void())
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
