//
//  View.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

protocol HasEmptyInitialization {
    init()
}

protocol BindsToViewModel: HasEmptyInitialization {
    associatedtype Input = Void
    associatedtype Output = Void
    associatedtype ViewModel: BindableViewModel = EmptyViewModel
    
    @discardableResult
    func bind(to viewModel: ViewModel.Interface, with input: Input) -> Output
    
    static func make() -> Self
}

extension BindsToViewModel {
    static func make() -> Self {
        return Self()
    }
}

protocol EmptyViewModelInterface {}

final class EmptyViewModel {
    lazy var router: Router = deferred()
    lazy var dependencies: Dependencies = deferred()
}

extension EmptyViewModel: BindableViewModel, EmptyViewModelInterface {
    typealias Interface = EmptyViewModelInterface
    
    final class Router: Routing {
        init(_ vc: UIViewController) {}
    }
}
