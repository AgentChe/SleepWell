//
//  NSObjectExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 05/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import Foundation

extension NSObject: Setupable {}

protocol Setupable {}

extension Setupable {
    
    func setup(closure: ((Self) -> Void)) -> Self {
        closure(self)
        return self
    }
}
