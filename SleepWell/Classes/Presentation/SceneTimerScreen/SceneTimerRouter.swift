//
//  SceneTimerRouter.swift
//  SleepWell
//
//  Created by Alexander Mironov on 29/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class SceneTimerRouter: Routing {
    private let router: Router
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func dismiss() {
        router.dismiss()
    }
}
