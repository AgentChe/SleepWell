//
//  PaygateRouter.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class PaygateRouter: Routing {
    private let router: Router
    
    required init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
}
