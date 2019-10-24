//
//  DateExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

extension Date {
    static let minuteAndSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    static let hourAndMinutesFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let hourMinutesSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    static let dayMonthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter
    }()
    
    static let yearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var minuteAndSeconds: String {
        return Date.minuteAndSecondsFormatter.string(from: self)
    }
    
    var hourAndMinutes: String {
        return Date.hourAndMinutesFormatter.string(from: self)
    }
    
    var dayMonthYear: String {
        return Date.dayMonthYearFormatter.string(from: self)
    }

    var yearMonthDay: String {
        return Date.yearMonthDayFormatter.string(from: self)
    }
}

extension TimeInterval {
    var minuteAndSeconds: String {
        let date = Date(timeIntervalSince1970: self)
        return date.minuteAndSeconds
    }
    
    var hourAndMinutes: String {
        let date = Date(timeIntervalSince1970: self)
        return date.hourAndMinutes
    }
    
    var dayMonthYear: String {
        let date = Date(timeIntervalSince1970: self)
        return date.dayMonthYear
    }
    
    var yearMonthDay: String {
        let date = Date(timeIntervalSince1970: self)
        return date.yearMonthDay
    }
}

