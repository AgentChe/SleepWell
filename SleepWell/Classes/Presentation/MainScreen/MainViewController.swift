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

enum MainRoute {
    case paygate
    case play(RecordingDetail)
}

final class MainViewController: UIViewController {
    
    @IBOutlet private var tabBarView: TabBarView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var tabBarHeight: NSLayoutConstraint!
    private var storiesController: StoriesViewController!
    private var meditateController: MeditateViewController!
    private var paygateController: PaygateViewController!
    
    private let storiesTabItem = TabBarItem()
    private let meditateTabItem = TabBarItem()
    private let sceneTabItem = TabBarItem()
    
    private lazy var router = Router(transitionHandler: self)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }
    
    private func setStories(behave: MainScreenBehave, completion: ((MainRoute) -> Void)?) {
        if storiesController == nil {
            storiesController = StoriesAssembly().assemble(input: StoriesViewController.Input(isActiveSubscription: behave == .withActiveSubscription, completion: completion)).vc
        }
        storiesController.view.frame = containerView.bounds
        add(storiesController)
    }
    
    private func setMeditate(behave: MainScreenBehave, completion: ((MainRoute) -> Void)?) {
        if meditateController == nil {
            meditateController = MeditateAssembly().assemble(input: MeditateViewController.Input(isActiveSubscription: behave == .withActiveSubscription, completion: completion)).vc
        }
        meditateController.view.frame = containerView.bounds
        add(meditateController)
    }
    
    private func setupTabs() {
        storiesTabItem.title = "Stroies"
        meditateTabItem.title = "Meditate"
        sceneTabItem.title = "Scene"
        
        tabBarView.items = [storiesTabItem, meditateTabItem, sceneTabItem]
    }
    
    func showTabBar(shouldMove: Bool) {
        if shouldMove {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseIn,
                           animations: {
                            self.view.frame.size.height += self.tabBarView.bounds.height
                            
                            self.view.layoutIfNeeded()
            }) { (finished) in
                
            }
        } else {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseOut,
                           animations: {
                            print(self.tabBarView.frame.origin.y)
                            self.view.frame.size.height -= self.tabBarView.bounds.height
                            
                            self.view.layoutIfNeeded()
            }) { (finished) in

            }
        }
    }
    
    private let disposeBag = DisposeBag()
}

extension MainViewController: BindsToViewModel {
    enum Tab: Int {
        case stories
        case meditate
        case scene
    }

    typealias ViewModel = MainViewModel
    
    struct Input {
        let behave: MainScreenBehave
    }
    
    static func make() -> MainViewController {
        let storyboard = UIStoryboard(name: "MainScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
    }
    
    func bind(to viewModel: MainViewModelInterface, with input: Input) -> () {
        tabBarView.selectIndex
            .map { Tab(rawValue: $0) ?? .scene }
            .emit(onNext: { [weak self] tab in
                switch tab {
                case .meditate:
                    self?.setMeditate(behave: input.behave, completion: { [weak self] route in
                        switch route {
                        case .paygate:
                            self?.router.present(type: PaygateAssembly.self, input: (openedFrom: .paidContent, completion: { result in
                                print(result)
                            }))
                        case let .play(recording):
                            print(recording)
                        }
                    })
                case .stories:
                    self?.setStories(behave: input.behave, completion: { [weak self] route in
                        switch route {
                        case .paygate:
                            self?.router.present(type: PaygateAssembly.self, input: (openedFrom: .paidContent, completion: { result in
                                print(result)
                            }))
                        case let .play(recording):
                            print(recording)
                        }

                    })
                case .scene:
                    break
                }
            })
            .disposed(by: disposeBag)
        
//        Signal<Bool>.just(true).delay(.seconds(5)).emit(onNext: { [weak self] state in
//            self?.showTabBar(shouldMove: state)
//        }).disposed(by: disposeBag)
//
//        Signal<Bool>.just(false).delay(.seconds(10)).emit(onNext: { [weak self] state in
//            self?.showTabBar(shouldMove: state)
//        }).disposed(by: disposeBag)
        
    }
}

private extension MainViewController {
    func add(_ child: UIViewController) {
        remove()
        addChild(child)
        containerView.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        if let child = children.last {
            willMove(toParent: nil)
            containerView.subviews.last?.removeFromSuperview()
            child.removeFromParent()
        }
    }
}
