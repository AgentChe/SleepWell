//
//  MeditateRouter.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class MeditateRouter: Routing {
    private let router: Router
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
}
