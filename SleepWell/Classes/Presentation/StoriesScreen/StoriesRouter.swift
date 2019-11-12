//
//  StoriesRouter.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright (c) 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class StoriesRouter: Routing {
    private let router: Router
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
}
