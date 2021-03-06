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
    case paygate(PaygateViewModel.PaygateOpenedFrom)
    case play(RecordingDetail)
}

final class MainViewController: UIViewController {
    
    @IBOutlet private var tabBarView: ScrollTabBarView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var tabBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTabs()
        RateManager.secondLaunch()
    }

    private func setupTabs() {
        storiesTabItem.title = "Stories"
        meditateTabItem.title = "Meditate"
        sceneTabItem.title = "Scenes"
        soundTabItem.title = "Sounds"
        
        sceneTabItem.select = true 
        
        tabBarView.items = [storiesTabItem, meditateTabItem, sceneTabItem, soundTabItem]
    }
    
    private var meditateAssambly: (vc: MeditateViewController, output: Signal<MainRoute>)!
    private var storiesAssambly: (vc: StoriesViewController, output: Signal<MainRoute>)!
    private var scenesAssambly: (vc: ScenesViewController, output: Signal<MainRoute>)!
    private var soundsAssambly: (vc: SoundsViewController, output: Signal<MainRoute>)!
    
    private let storiesTabItem = TabItem()
    private let meditateTabItem = TabItem()
    private let sceneTabItem = TabItem()
    private let soundTabItem = TabItem()
    private let disposeBag = DisposeBag()
}

extension MainViewController: BindsToViewModel {
    enum Tab: Int {
        case stories
        case meditate
        case scene
        case sound
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
        
        let subscriptionExpired = viewModel
            .monitorSubscriptionExpiration(triggers: [AppStateProxy.ApplicationProxy.didBecomeActive.asObservable()])
            .map { !$0 }
            .startWith(input.behave == .withActiveSubscription)
            .distinctUntilChanged()
            .asObservable()
        
        let isActiveSubscription = Observable
            .merge(paygateSignal, subscriptionExpired)
            .share(replay: 1, scope: .forever)

        let selectIndex = tabBarView.selectIndex
        
        let storiesScroll = selectIndex
            .scan((old: Int?.none, new: Tab.stories.rawValue)) { old, new in
                (old: old.new, new: new)
            }
            .filter { $0.old == $0.new && $0.new == Tab.stories.rawValue  }
            .map { _ in () }
        
        let meditationScroll = selectIndex
            .scan((old: Int?.none, new: Tab.meditate.rawValue)) { old, new in
                (old: old.new, new: new)
            }
            .filter { $0.old == $0.new && $0.new == Tab.meditate.rawValue  }
            .map { _ in () }
        
        selectIndex
            .map { Tab(rawValue: $0) ?? .scene }
            .flatMapLatest { [weak self] tab -> Signal<MainRoute> in
                guard let self = self else { return .empty() }
                switch tab {
                case .meditate:
                    return self.meditate(behave: isActiveSubscription, scrollToTop: meditationScroll)
                case .stories:
                    return self.stories(behave: isActiveSubscription, scrollToTop: storiesScroll)
                case .scene:
                    return self.scenes(
                        behave: isActiveSubscription,
                        isMainScreen: selectIndex
                            .map { $0 == Tab.scene.rawValue }
                            .asDriver(onErrorDriveWith: .empty())
                            .startWith(true)
                    )
                case .sound :
                    let isMainScreen = selectIndex
                        .map { $0 == Tab.sound.rawValue }
                        .asDriver(onErrorDriveWith: .empty())
                        .startWith(true)
                    return self.sounds(isMainScreen: isMainScreen, isActiveSubscription: isActiveSubscription)
                }
            }
            .emit(to: Binder(self) { base, route in
                switch route {
                case .paygate(let from):
                    viewModel.showPaygateScreen(from: from, completion: { paygateRelay.accept($0) })
                case .play(let detail):
                    base.hideTabBar(isHidden: true)
                    viewModel.showPlayerScreen(
                        detail: detail,
                        hideTabbarClosure: { [weak base] state in
                            base?.hideTabBar(isHidden: state)
                        },
                        didStartPlaying: { [weak base] name in
                            base?.tabBarView.showMiniPlayer(name: name)
                        },
                        didPause: { [weak base] in
                            base?.tabBarView.hideMiniPlayer()
                        }
                    )
                }
            })
            .disposed(by: disposeBag)
        
        let didPauseRecording = tabBarView.didTapMiniPlayer
            .filter { $0 == .pause }
            .flatMapFirst { _ in viewModel.pauseRecording(style: .force) }
        
        didPauseRecording
            .emit()
            .disposed(by: disposeBag)
        
        didPauseRecording
            .withLatestFrom(
                selectIndex
                    .map { $0 == Tab.sound.rawValue }
                    .asDriver(onErrorDriveWith: .empty())
            )
            .filter { $0 }
            .map { _ in () }
            .emit(to: viewModel.playNoise)
            .disposed(by: disposeBag)
        
        tabBarView.didTapMiniPlayer
            .filter { $0 == .play }
            .flatMapFirst { _ in
                Signal.zip(viewModel.pauseNoise(), viewModel.pauseScene(style: .force))
            }
            .flatMapLatest { _ in viewModel.playRecording(style: .force) }
            .emit()
            .disposed(by: disposeBag)
        
        viewModel.isPlaying
            .drive(tabBarView.setPlayerState)
            .disposed(by: disposeBag)
    }
}

private extension MainViewController {
    
    func meditate(behave: Observable<Bool>, scrollToTop: Signal<Void>) -> Signal<MainRoute> {
        if meditateAssambly == nil {
            meditateAssambly = MeditateAssembly().assemble(input: .init(
                subscription: behave,
                scrollToTop: scrollToTop
            ))
        }
        meditateAssambly.vc.view.frame = containerView.bounds
        add(meditateAssambly.vc)
        return meditateAssambly.output
    }
    
    func stories(behave: Observable<Bool>, scrollToTop: Signal<Void>) -> Signal<MainRoute> {
        if storiesAssambly == nil {
            storiesAssambly = StoriesAssembly().assemble(input: .init(
                subscription: behave,
                scrollToTop: scrollToTop
            ))
        }
        storiesAssambly.vc.view.frame = containerView.bounds
        add(storiesAssambly.vc)
        return storiesAssambly.output
    }

    func scenes(behave: Observable<Bool>, isMainScreen: Driver<Bool>) -> Signal<MainRoute> {
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
    
    func sounds(isMainScreen: Driver<Bool>, isActiveSubscription: Observable<Bool>) -> Signal<MainRoute> {
        if soundsAssambly == nil {
            soundsAssambly = SoundsAssembly().assemble(input: .init(
                isActiveSubscription: isActiveSubscription,
                isMainScreen: isMainScreen,
                hideTabbarClosure: { [weak self] state in
                    self?.hideTabBar(isHidden: state)
                }
            ))
        }
        soundsAssambly.vc.view.frame = containerView.bounds
        add(soundsAssambly.vc)
        return soundsAssambly.output
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
        tabBarHeight.constant = isHidden ? 0 : GlobalDefinitions.tabBarHeight

        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
}
