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
    
    func showPlayerScreen(
        detail: RecordingDetail,
        hideTabbarClosure: @escaping (Bool) -> Void,
        didStartPlaying: @escaping (String) -> Void,
        didPause: @escaping () -> Void
    ) {
        router.presentChild(
            type: PlayerAssembly.self,
            input: .init(
                recording: detail,
                hideTabbarClosure: hideTabbarClosure,
                didStartPlaying: didStartPlaying,
                didPause: didPause
            ),
            at: 1
        )
    }
    
    func showPaygateScreen(from: PaygateViewModel.PaygateOpenedFrom, completion: ((PaygateCompletionResult) -> (Void))?) {
        router.present(
            type: PaygateAssembly.self,
            input: (openedFrom: from, completion: completion)
        )
    }
}
