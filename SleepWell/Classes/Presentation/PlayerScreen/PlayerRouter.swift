//
//  PlayerRouter.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class PlayerRouter: Routing {
    private let router: Router
    
    required init(transitionHandler: UIViewController) {
        router = Router(transitionHandler: transitionHandler)
    }
    
    func goToVolumeScreen(recording: RecordingDetail) {
        router.present(type: VolumeAssembly.self, input: .init(recording: recording))
    }
}
