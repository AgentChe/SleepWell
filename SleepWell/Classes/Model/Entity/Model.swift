//
//  Model.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

protocol Model: Codable { }

extension Model {
    static func parse(from data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }

    static func parseArray(from data: Data) -> [Self] {
        return (try? JSONDecoder().decode([Self].self, from: data)) ?? []
    }

    static func parseFromArray(any: Any) -> [Self] {
        guard
            let array = any as? [[String: AnyObject]],
            let data = try? JSONSerialization.data(withJSONObject: array)
        else {
            return []
        }

        return (try? JSONDecoder().decode([Self].self, from: data)) ?? []
    }
    
    static func parseFromDictionary(any: Any) -> Self? {
        guard
            let dict = any as? [String: AnyObject],
            let data = try? JSONSerialization.data(withJSONObject: dict, options: [])
        else {
            return nil
        }

        return try? parse(from: data)
    }
    
    static func encode(object: Self) throws -> Data {
        return try JSONEncoder().encode(object)
    }
}
