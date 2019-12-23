//
//  UrlExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 24/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

extension URL {
    
    var localUrl: URL {
        let string = absoluteString
        do {
            let regex = try NSRegularExpression(
                pattern: "\\.|/|:",
                options: NSRegularExpression.Options.caseInsensitive
            )
            let type = String(string.split(separator: ".").last ?? "")
            let withoutType = String(string.dropLast(type.count + 1))
            let range = NSMakeRange(0, withoutType.count)
            let result = regex.stringByReplacingMatches(
                in: withoutType,
                options: [],
                range: range,
                withTemplate: "_"
            )
            
            if let local = Bundle.main.path(forResource: result, ofType: type) {
                return URL(fileURLWithPath: local)
            }
            return self
        } catch {
            return self
        }
    }
}
