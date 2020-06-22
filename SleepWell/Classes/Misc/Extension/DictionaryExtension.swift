//
//  DictionaryExtension.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 31/03/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

extension Dictionary {
    mutating func merge(dict: [Key: Value]) {
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
