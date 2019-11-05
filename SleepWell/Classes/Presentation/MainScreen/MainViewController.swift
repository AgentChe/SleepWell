//
//  MainViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum MainScreenBehave {
    case withActiveSubscription, withoutActiveSubscription
}

final class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print()
    }
    
    private let disposeBag = DisposeBag()
}

extension MainViewController: BindsToViewModel {
    typealias ViewModel = MainViewModel
    
    struct Input {
        let behave: MainScreenBehave
    }
    
    func bind(to viewModel: MainViewModelInterface, with input: Input) -> () {
        print(input)
        
        Signal<MainViewModel.Tab>
            .just(.stories)
            .delay(.seconds(1))
            .emit(onNext: {
                viewModel.selectTab($0, behave: input.behave)
            })
        .disposed(by: disposeBag)
        
    }
}
