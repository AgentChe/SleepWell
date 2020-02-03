//
//  SoundsRouter.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright (c) 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxCocoa

final class SoundsRouter: Routing {
    private let router: Router
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func showSleepTimerScreen() {
        router.present(type: SceneTimerAssembly.self, input: .sounds)
    }
}
