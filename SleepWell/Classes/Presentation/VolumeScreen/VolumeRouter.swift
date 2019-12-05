//
//  VolumeRouter.swift
//  SleepWell
//
//  Created by Alexander Mironov on 10/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class VolumeRouter: Routing {
    private let router: Router
    
    required init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func dismiss() {
        router.dismiss()
    }
}
