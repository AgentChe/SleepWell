//
//  MainViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift

final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print()
    }
}

extension MainViewController: BindsToViewModel {
    typealias ViewModel = MainViewModel
    
    func bind(to viewModel: MainViewModelInterface, with input: ()) -> () {
        
    }
}
