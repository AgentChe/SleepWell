//
//  ArrayExtension.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

extension Array {
    
    func item(at index: Int) -> Element? {
        guard index >= 0 && index < count else {
            return nil
        }
        return self[index]
    }
}
