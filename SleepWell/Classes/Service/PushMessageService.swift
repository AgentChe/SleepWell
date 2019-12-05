//
//  PushNotificationsService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Firebase
import RxSwift

enum PushNotificationAuthorizationStatus {
    case authorized, denied, notDetermined
}

final class PushMessagesService {
    static let shared = PushMessagesService()
    
    private init() {}
    
    func configure() { }
    
    func register(handler: ((_ isRegisteredForRemoteNotifications: Bool, _ token: String?) -> Void)? = nil) {
        func completionRegister() {
            let status = notificationStatus
            
            if status == .denied {
                handler?(false, nil)
            } else if status == .authorized, let token = Messaging.messaging().fcmToken {
                handler?(true, token)
            }
        }
        
        AppStateProxy.PushNotificationsProxy.notifyAboutPushTokenHasArrived = {
            completionRegister()
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { granted, error in
            DispatchQueue.main.async {
                completionRegister()
            }
        })
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    var notificationStatus: PushNotificationAuthorizationStatus {
        var result: PushNotificationAuthorizationStatus!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                result = PushNotificationAuthorizationStatus.authorized
            } else if settings.authorizationStatus == .notDetermined {
                result = PushNotificationAuthorizationStatus.notDetermined
            } else {
                result = PushNotificationAuthorizationStatus.denied
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return result
    }
}

