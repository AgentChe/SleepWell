//
//  ViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

protocol BindableViewModel: HasEmptyInitialization {
    associatedtype Router: Routing
    associatedtype Dependencies = Void
    associatedtype Interface = EmptyViewModelInterface
    
    var router: Router { get set }
    var dependencies: Dependencies { get set }
}
