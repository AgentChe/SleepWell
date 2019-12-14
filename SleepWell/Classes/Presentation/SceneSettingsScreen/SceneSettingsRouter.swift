//
//  SceneSettingsRouter.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxCocoa
import UIKit

final class SceneSettingsRouter: Routing {
    private let router: Router
    
    required init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func showSleepTimerScreen(sceneDetail: SceneDetail) -> SceneTimerViewController.Output {
        router.present(type: SceneTimerAssembly.self, input: .init(sceneDetail: sceneDetail))
    }
}
