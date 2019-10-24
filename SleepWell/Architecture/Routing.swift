//
//  Routing.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

@discardableResult
func with<T>(_ object: T, do action: (T) -> Void) -> T {
    action(object)
    return object
}

func apply<T, R>(_ object: T, transform: (T) -> R) -> R {
    return transform(object)
}

func deferred<T>(file: StaticString = #file, line: UInt = #line) -> T {
    fatalError("Value isn't set before first use", file: file, line: line)
}

protocol Routing {
    init(_ vc: UIViewController)
}

final class Router: Routing {
    weak var transitionHandler: UIViewController?
    
    init(_ transitionHandler: UIViewController) {
        self.transitionHandler = transitionHandler
    }
}

private extension Router {
    func show<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        input: Assembly.VC.Input,
        transition: (UIViewController) -> Void
        ) -> Assembly.VC.Output {
        
        let assembly = Assembly()
        
        let tuple = assembly.assemble(input)
        
        transition(tuple.vc)
        
        return tuple.output
    }
}

extension Router {
    func pop(animated: Bool = true) {
        transitionHandler?.navigationController?.popViewController(animated: animated)
    }

    func pop(through count: Int, animated: Bool = true) {
        guard let stackViewControllers = transitionHandler?.navigationController?.viewControllers, stackViewControllers.count > count else {
            return
        }
        transitionHandler?.navigationController?.popToViewController(stackViewControllers[stackViewControllers.count - (count + 1)], animated: animated)
    }
    
    func dismiss() {
        transitionHandler?.dismiss(animated: true, completion: nil)
    }
    
    @discardableResult
    func push<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        input: Assembly.VC.Input,
        animated: Bool = true
    ) -> Assembly.VC.Output {
        
        return show(type, input: input) {
            self.transitionHandler?.navigationController?.pushViewController(
                $0,
                animated: animated
            )
        }
    }

    @discardableResult
    func presentChild<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        input: Assembly.VC.Input
    ) -> Assembly.VC.Output {

        return show(type, input: input) {
            self.transitionHandler?.addChild($0)
            self.transitionHandler?.view.addSubview($0.view)
            $0.view.frame = self.transitionHandler?.view.frame ?? .zero
        }
    }

    @discardableResult
    func present<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        input: Assembly.VC.Input,
        animated: Bool = true
    ) -> Assembly.VC.Output {
        
        return show(type, input: input) {
            let rootVC = self.transitionHandler?.navigationController
                ?? self.transitionHandler
            
            rootVC?.present(
                $0,
                animated: animated,
                completion: nil
            )
        }
    }
    
    @discardableResult
    func setRootVC<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        input: Assembly.VC.Input,
        animationOptions: UIView.AnimationOptions,
        duration: TimeInterval
    ) -> Assembly.VC.Output {

        return show(type, input: input) {

            let nc = UINavigationController(rootViewController: $0)
            guard let window = UIApplication.shared.keyWindow else {
                return
            }
            window.rootViewController = nc

            UIView.transition(
                with: window,
                duration: duration,
                options: animationOptions,
                animations: nil,
                completion: { [weak self] completed in
                    self?.transitionHandler?.dismiss(animated: false, completion: nil)
                }
            )
        }
    }
}

extension Router {

    @discardableResult
    func presentChild<Assembly: ScreenAssembly>(
        _ type: Assembly.Type
    ) -> Assembly.VC.Output where Assembly.VC.Input == Void {

        return presentChild(type, input: ())
    }

    @discardableResult
    func push<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        animated: Bool = true
    ) -> Assembly.VC.Output where Assembly.VC.Input == Void {
        
        return push(type, input: ())
    }
    
    @discardableResult
    func present<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        animated: Bool = true
    ) -> Assembly.VC.Output where Assembly.VC.Input == Void {
        
        return present(type, input: ())
    }

    @discardableResult
    func setRootVC<Assembly: ScreenAssembly>(
        _ type: Assembly.Type,
        animationOptions: UIView.AnimationOptions = .transitionCrossDissolve,
        duration: TimeInterval = 0.3
    ) -> Assembly.VC.Output where Assembly.VC.Input == Void {
        return setRootVC(
            type,
            input: (),
            animationOptions: animationOptions,
            duration: duration
        )
    }
}
