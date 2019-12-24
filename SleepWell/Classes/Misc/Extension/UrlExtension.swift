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
        transformedToLocal ?? self
    }
    
    var isContained: Bool {
        transformedToLocal != nil
    }
    
    var localPath: String {
        let string = absoluteString
        let type = String(string.split(separator: ".").last ?? "")
        let withoutType = String(string.dropLast(type.count + 1))
        return withoutType.replacingRegexMatches(pattern: "/|:", with: "_")
            .replacingRegexMatches(pattern: "%20", with: " ")
    }
    
    private var transformedToLocal: URL? {
        let string = absoluteString
        let type = String(string.split(separator: ".").last ?? "")
        let withoutType = String(string.dropLast(type.count + 1))
        let result = withoutType.replacingRegexMatches(pattern: "/|:", with: "_")
            .replacingRegexMatches(pattern: "%20", with: " ")
        
        if let local = Bundle.main.path(forResource: result, ofType: type) {
            return URL(fileURLWithPath: local)
        }
        if let path = try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).path, FileManager.default.fileExists(atPath: path + "/" + result) {
            return URL(fileURLWithPath: path + "/" + result)
        }
        return nil
    }
}
