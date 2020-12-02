//
//  AppDelegate.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Firebase
import RxCocoa

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    let sdkProvider = SDKProvider()
    
    private let generateStepSignal = PublishRelay<Void>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "SplashScreen", bundle: .main)
        let splashViewController = storyboard.instantiateViewController(withIdentifier: "SplashViewController") as! SplashViewController
        splashViewController.generateStepSignal = generateStepSignal.asSignal()
        window?.rootViewController = splashViewController
        window?.makeKeyAndVisible()
        
        FirebaseApp.configure()
        RateManager.incrementRun()
        
        PushMessagesService.shared.updateLocalNotification()
        
        addDelegates()
        
        startSDKProvider(on: splashViewController.view)
        
        sdkProvider.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        sdkProvider.application(app, open: url, options: options)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        sdkProvider.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        sdkProvider.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        sdkProvider.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        sdkProvider.application(application, continue: userActivity, restorationHandler: restorationHandler)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppStateProxy.ApplicationProxy.didBecomeActive.accept(Void())
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        AppStateProxy.ApplicationProxy.didEnterBackground.accept(Void())
    }
}

// MARK: SDKPurchaseMediatorDelegate
extension AppDelegate: SDKPurchaseMediatorDelegate {
    func purchaseMediatorDidValidateReceipt(response: ReceiptValidateResponse?) {
        guard let response = response else {
            return
        }
        
        let session = Session(userToken: response.userToken,
                              activeSubscription: response.activeSubscription,
                              userId: response.userId)
        
        SessionService.store(session: session)
    }
}

// MARK: Private
private extension AppDelegate {
    func startSDKProvider(on view: UIView) {
        let sdkSettings = SDKSettings(backendBaseUrl: GlobalDefinitions.sdkDomainUrl,
                                      backendApiKey: GlobalDefinitions.sdkApiKey,
                                      amplitudeApiKey: GlobalDefinitions.amplitudeAPIKey,
                                      facebookActive: true,
                                      branchActive: true,
                                      firebaseActive: true,
                                      applicationTag: GlobalDefinitions.appNameForAmplitude,
                                      userToken: SessionService.session?.userToken,
                                      userId: SessionService.session?.userId,
                                      view: view,
                                      shouldAddStorePayment: true,
                                      isTest: false)
        
        sdkProvider.initialize(settings: sdkSettings) { [weak self] in
            self?.generateStepSignal.accept(Void())
        }
    }
    
    func addDelegates() {
        SDKStorage.shared.purchaseMediator.add(delegate: self)
    }
}
