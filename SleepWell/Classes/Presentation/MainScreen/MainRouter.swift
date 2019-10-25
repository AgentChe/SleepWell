//
//  MainRouter.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class MainRouter: Routing {
    private let router: Router
    
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
}
