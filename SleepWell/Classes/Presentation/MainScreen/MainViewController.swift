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
    
    private lazy var router = Router(transitionHandler: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
    }

    private func setupTabs() {
        storiesTabItem.title = "Stories"
        meditateTabItem.title = "Meditate"
        sceneTabItem.title = "Scene"
        
        tabBarView.backgroundColor = .black
        tabBarView.items = [storiesTabItem, meditateTabItem, sceneTabItem]
    }
    
    private var meditateAssambly: (vc: MeditateViewController, output: Signal<MainRoute>)!
    private var storiesAssambly: (vc: StoriesViewController, output: Signal<MainRoute>)!
    private var scenesAssambly: (vc: ScenesViewController, output: Signal<MainRoute>)!
    
    private let storiesTabItem = TabBarItem()
    private let meditateTabItem = TabBarItem()
    private let sceneTabItem = TabBarItem()
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
        let paygateRelay = PublishRelay<PaygateCompletionResult>()
        
        let behaveSignal = Observable.deferred { .just(input.behave == .withActiveSubscription) }
        let paygateSignal = paygateRelay
            .flatMapLatest { paygateResult -> Signal<Bool> in
                switch paygateResult {
                case .purchased, .restored:
                    return viewModel.sendPersonalData()
                case .closed:
                    return .just(false)
                }
            }
            .asObservable()
        
        let isActiveSubscription = Observable
            .merge(behaveSignal, paygateSignal)
            .share(replay: 1, scope: .forever)

        let selectIndex = tabBarView.selectIndex
        
        selectIndex
            .map { Tab(rawValue: $0) ?? .scene }
            .flatMapLatest { [weak self] tab -> Signal<MainRoute> in
                guard let self = self else { return .empty() }
                switch tab {
                case .meditate:
                    return self.meditate(behave: isActiveSubscription)
                case .stories:
                    return self.stories(behave: isActiveSubscription)
                case .scene:
                    return self.scenes(
                        behave: isActiveSubscription,
                        isMainScreen: selectIndex
                            .map { $0 == Tab.scene.rawValue }
                            .startWith(true)
                    )
                }
            }
            .emit(to: Binder(self) { base, route in
                switch route {
                case .paygate:
                    base.router.present(type: PaygateAssembly.self, input: (openedFrom: .paidContent, completion: { result in
                        paygateRelay.accept(result)
                    }))
                case let .play(detail):
                    base.setPlayer(detail)
                }
            })
            .disposed(by: disposeBag)
    }
}

private extension MainViewController {
    func setPlayer(_ detail: RecordingDetail) {
        let playerController = PlayerAssembly().assemble(input: .init(
            recording: detail,
            hideTabbarClosure: { [weak self] state in
                self?.hideTabBar(isHidden: state)
            }
        )).vc
        playerController.view.frame = view.bounds
        addChild(playerController)
        view.insertSubview(playerController.view, at: 1)
        didMove(toParent: self)
    }
    
    func meditate(behave: Observable<Bool>) -> Signal<MainRoute> {
        if meditateAssambly == nil {
            meditateAssambly = MeditateAssembly().assemble(input: behave)
        }
        meditateAssambly.vc.view.frame = containerView.bounds
        add(meditateAssambly.vc)
        return meditateAssambly.output
    }
    
    func stories(behave: Observable<Bool>) -> Signal<MainRoute> {
        if storiesAssambly == nil {
            storiesAssambly = StoriesAssembly().assemble(input: behave)
        }
        storiesAssambly.vc.view.frame = containerView.bounds
        add(storiesAssambly.vc)
        return storiesAssambly.output
    }

    func scenes(
        behave: Observable<Bool>,
        isMainScreen: Signal<Bool>
    ) -> Signal<MainRoute> {
        if scenesAssambly == nil {
            scenesAssambly = ScenesAssembly().assemble(input: .init(
                subscription: behave,
                isMainScreen: isMainScreen,
                hideTabbarClosure: { [weak self] state in
                    self?.hideTabBar(isHidden: state)
                }
            ))
        }
        scenesAssambly.vc.view.frame = containerView.bounds
        add(scenesAssambly.vc)
        return scenesAssambly.output
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
            containerView.subviews.first(where: { $0 === child.view })?.removeFromSuperview()
            child.removeFromParent()
        }
    }

    func hideTabBar(isHidden: Bool) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: isHidden ? .curveEaseOut : .curveEaseIn,
            animations: {
                self.tabBarHeight.constant = isHidden ? 0 : GlobalDefinitions.tabBarHeight
                self.tabBarView.alpha = isHidden ? 0 : 1
                self.view.layoutIfNeeded()
        }) { _ in
            
        }
    }
}



