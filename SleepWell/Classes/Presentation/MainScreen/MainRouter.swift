//
//  MainRouter.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class MainRouter: Routing {
    enum Route {
        case meditate
        case stories
        case scenes
    }
    
    private let router: Router
    
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func trigger(_ route: Route) {
        switch route {
        case .meditate:
            break
        case .stories:
            router.presentChild(type: StoriesAssembly.self)
        case .scenes:
            break
        }
    }
}
