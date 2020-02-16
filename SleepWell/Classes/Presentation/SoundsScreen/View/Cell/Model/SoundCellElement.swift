//
//  SoundCellElement.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 19/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import Foundation.NSURL

struct SoundCellElement {
    let noise: Noise 
    let paid: Bool
    
    static func map(noises: [Noise], isActiveSubscription: Bool) -> [SoundCellElement] {
        return noises.map {
            SoundCellElement(noise: $0, paid: isActiveSubscription ? true : !$0.paid)
        }
    }
}
