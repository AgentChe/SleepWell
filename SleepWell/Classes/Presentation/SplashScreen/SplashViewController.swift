//
//  SplashViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift

class SplashViewController: UIViewController {
    private lazy var router = Router(transitionHandler: self)
    private let viewModel = SplashViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        router.presentChild(type: StoriesAssembly.self)
    }
}
