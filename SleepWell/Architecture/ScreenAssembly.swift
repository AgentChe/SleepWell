//
//  ScreenAssembly.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

protocol ScreenAssembly: HasEmptyInitialization {
    associatedtype VC: (UIViewController & BindsToViewModel)
    
    func assembleDependencies() -> VC.ViewModel.Dependencies
}

extension ScreenAssembly where VC.ViewModel.Dependencies == Void {
    func assembleDependencies() -> VC.ViewModel.Dependencies {
        return Void()
    }
}

extension ScreenAssembly {
    func assemble(_ input: VC.Input) -> (vc: VC, output: VC.Output) {
        let vc = VC.make()
        
        var vm = VC.ViewModel()
        let interface = vm.configure(
            router: VC.ViewModel.Router(vc),
            dependecies: assembleDependencies()
        )
        
        let output = vc.bind(to: interface, with: input)
        
        vc.loadViewIfNeeded()
        
        return (vc: vc, output: output)
    }
}

private extension BindableViewModel {
    mutating func configure(router: Router, dependecies: Dependencies) -> Interface {
        self.router = router
        self.dependencies = dependecies
        
        return self as! Self.Interface
    }
}
