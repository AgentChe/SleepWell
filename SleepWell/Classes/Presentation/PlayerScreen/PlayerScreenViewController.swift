//
//  PlayerScreenViewController.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class PlayerScreenViewController: UIViewController {
    
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
    private let disposeBag = DisposeBag()
}

extension PlayerScreenViewController: BindsToViewModel {
    typealias ViewModel = PlayerScreenViewModel
    
    static func make() -> PlayerScreenViewController {
        let storyboard = UIStoryboard(name: "PlayerScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "PlayerScreenViewController")
            as! PlayerScreenViewController
    }
    
    func bind(to viewModel: PlayerScreenViewModelInterface, with input: ()) {
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
        
        let heightToDissmiss = view.frame.height / 3
        
        let beingDissmissed = panEvent.filter { $0 >= heightToDissmiss }
            .take(1)
        
        panGesture.rx.event
            .filter { $0.state == .ended }
            .withLatestFrom(beingDissmissed.map { _ in true }.startWith(false))
            .filter { !$0 }
            .bind(to: Binder(self) { base, _ in
                UIView.animate(withDuration: 0.5, animations: {
                    base.view.frame = .init(
                        x: base.view.frame.minX,
                        y: 0,
                        width: base.view.frame.width,
                        height: base.view.frame.height
                    )
                })
            })
            .disposed(by: disposeBag)
        
        panEvent
            .filter { $0 < heightToDissmiss && $0 > 0 }
            .bind(to: Binder(self) { base, y in
                 base.view.frame = .init(
                    x: base.view.frame.minX,
                    y: y,
                    width: base.view.frame.width,
                    height: base.view.frame.height
                )
            })
            .disposed(by: disposeBag)
        
        beingDissmissed
            .bind(to: Binder(self) { base, _ in
                UIView.animate(
                    withDuration: 0.5,
                    animations: {
                        base.view.frame = .init(
                            x: base.view.frame.minX,
                            y: base.view.frame.maxY,
                            width: base.view.frame.width,
                            height: base.view.frame.height
                        )
                    },
                    completion: { _ in
                        base.removeFromParent()
                    }
                )
            })
            .disposed(by: disposeBag)
    }
}
