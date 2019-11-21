//
//  ScenesRouter.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxCocoa

final class ScenesRouter: Routing {
    private let router: Router
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func showSettings(sceneDetail: SceneDetail) -> Signal<Void> {
        router.presentChild(type: SceneSettingsAssembly.self, input: .init(sceneDetail: sceneDetail))
            .didDismiss
    }
}
