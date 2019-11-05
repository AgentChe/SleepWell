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
    
    enum Route {
        case details(StoryDetail)
        case paygate(_ completion: (PaygateCompletionResult) -> ())
    }
  
    init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func trigger(_ route: Route) {
        switch route {
        case let .details(detail):
            router.presentChild(type: PlayerAssembly.self, input: .init(recording: detail))
        case let .paygate(completion):
            router.present(type: PaygateAssembly.self, input: PaygateViewController.Input(openedFrom: .paidContent, completion: completion))
        }
    }
}
