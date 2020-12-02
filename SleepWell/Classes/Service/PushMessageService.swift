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
    
    private func getRepeatDate(time: String? = nil) -> Date? {
        guard let time = time ?? PersonalDataService.cachedPersonalData()?.pushTime else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        dateFormatter.locale = Locale.current
        guard let date = dateFormatter.date(from: time) else {
            return nil
        }
        return Calendar.current.date(byAdding: .minute, value: -30, to: date)
    }
    
    func addLocalNotification(time: String? = nil, currentDate: Date = Date()) {
        guard let pushTime = getRepeatDate(time: time) else {
            return
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: pushTime)
        let minutes = calendar.component(.minute, from: pushTime)
        
        let center = UNUserNotificationCenter.current()
        
        PushMessagesService.messageArray.enumerated().forEach { index, notifyData in
            guard let pushDate = calendar.date(byAdding: .day, value: index, to: currentDate) else {
                return
            }
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minutes
            dateComponents.day = calendar.component(.day, from: pushDate)
            dateComponents.month = calendar.component(.month, from: pushDate)
            
            let content = UNMutableNotificationContent()
            content.title = notifyData.title.localized
            content.body = notifyData.body.localized
            content.sound = UNNotificationSound.default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
            
            (1...3).forEach { item in
                guard let date = calendar.date(byAdding: .day, value: 10 * item, to: pushDate) else {
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = notifyData.title.localized
                content.body = notifyData.body.localized
                content.sound = UNNotificationSound.default
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minutes
                dateComponents.day = calendar.component(.day, from: date)
                dateComponents.month = calendar.component(.month, from: date)
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

                center.add(request)
            }
        }
    }
    
    func updateLocalNotification() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { [weak self] requests in
            if requests.count < 10,
                let trigger = requests.last?.trigger as? UNCalendarNotificationTrigger,
                let date = Calendar.current.date(from: trigger.dateComponents)
            {
                self?.addLocalNotification(currentDate: date)
            } else if requests.count == 0 {
                self?.addLocalNotification()
            }
        }
    }
    
    private static let messageArray: [(title: String, body: String)] = [
        (title: "local_notify_title_1", body: "local_notify_body_1"),
        (title: "local_notify_title_2", body: "local_notify_body_2"),
        (title: "local_notify_title_3", body: "local_notify_body_3"),
        (title: "local_notify_title_4", body: "local_notify_body_4"),
        (title: "local_notify_title_5", body: "local_notify_body_5"),
        (title: "local_notify_title_6", body: "local_notify_body_6"),
        (title: "local_notify_title_7", body: "local_notify_body_7"),
        (title: "local_notify_title_8", body: "local_notify_body_8"),
        (title: "local_notify_title_9", body: "local_notify_body_9"),
        (title: "local_notify_title_10", body: "local_notify_body_10")
    ]
}

