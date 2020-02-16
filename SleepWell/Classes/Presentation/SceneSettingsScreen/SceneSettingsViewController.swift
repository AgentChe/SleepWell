//
//  SceneSettingsViewController.swift
//  SleepWell
//
//  Created by Alexander Mironov on 19/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SceneSettingsViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var defaultView: UIView!
    @IBOutlet weak var randomView: UIView!
    @IBOutlet weak var sleepTimerView: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var sliderImageView: UIImageView!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    private let disposeBag = DisposeBag()
}

extension SceneSettingsViewController: BindsToViewModel {
    typealias ViewModel = SceneSettingsViewModel

    struct Input {
        let sceneDetail: SceneDetail
    }
    
    struct Output {
        let didDismiss: Signal<Void>
    }

    static func make() -> SceneSettingsViewController {
        let storyboard = UIStoryboard(name: "SceneSettingsScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "SceneSettingsViewController")
            as! SceneSettingsViewController
    }

    func bind(to viewModel: SceneSettingsViewModelInterface, with input: Input) -> Output {
        Analytics.shared.log(with: .sceneSettingsScr)
        
        let soundsCount = input.sceneDetail.sounds.count
        let maxHeight = view.frame.height - 304
        let defaultHeight = CGFloat(soundsCount * 48 + (soundsCount - 1) * 24)
        let maxDivider: CGFloat = max(defaultHeight / maxHeight, 1)
        let divider = maxDivider > 1.3 ? 1.0 : maxDivider
        let height = CGFloat(soundsCount * 48) / divider + CGFloat((soundsCount - 1) * 24) / divider
        
        rx.methodInvoked(#selector(UIViewController.viewDidLayoutSubviews))
            .take(1)
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: Binder(self) { base, _ in
                base.stackView.spacing = 24 / divider
                base.stackViewHeight.constant = height
                base.blurView.effect = nil
                
                UIView.animate(
                    withDuration: 1,
                    animations: {
                        base.blurView.effect = UIBlurEffect(style: .dark)
                        base.randomView.alpha = 1
                        base.defaultView.alpha = 1
                        base.sleepTimerView.alpha = 1
                        base.sliderImageView.alpha = 1
                        base.stackView.alpha = 1
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let defaultTapGesture = UITapGestureRecognizer()
        defaultView.addGestureRecognizer(defaultTapGesture)
        let defaultVolumes = defaultTapGesture.rx.event.asSignal()
            .do(onNext: { _ in Analytics.shared.log(with: .sceneDefaultTap) })
            .map { _ in Float(0.75) }
        
        let randomTapGesture = UITapGestureRecognizer()
        randomView.addGestureRecognizer(randomTapGesture)
        let randomVolumes = randomTapGesture.rx.event.asSignal()
            .do(onNext: { _ in Analytics.shared.log(with: .sceneRandomTap) })
        
        let sleepTimerTapGesture = UITapGestureRecognizer()
        sleepTimerView.addGestureRecognizer(sleepTimerTapGesture)
        
        let showSleepTimer = sleepTimerTapGesture.rx.event.asSignal()
            .do(onNext: { [weak self] _ in
                self?.view.alpha = 0
                
                Analytics.shared.log(with: .sceneSleepTimerTap)
            })
            .map { _ in
                viewModel.showSleepTimerScreen(sceneDetail: input.sceneDetail)
            }
        
        showSleepTimer.flatMapLatest { $0.appeared }
            .emit(to: Binder(self) { base, _ in
                base.view.alpha = 0
            })
            .disposed(by: disposeBag)

        showSleepTimer.flatMapLatest { $0.didDismiss }
            .emit(to: Binder(self) { base, _ in
                base.view.alpha = 1
            })
            .disposed(by: disposeBag)
        
        let volumes = viewModel.currentScenePlayersVolume ?? []
        input.sceneDetail.sounds.forEach { sound in
            let view = VolumeSliderView()
            view.configure(input: .init(
                text: sound.name,
                initialValue: volumes.first(where: { $0.id == sound.id })?.value ?? 0.0,
                programmaticallyValue: Signal.merge(defaultVolumes, randomVolumes.map { _ in Float.random(in: 0...1) })
            ))
            stackView.addArrangedSubview(view)
            
            view.volume.map { (sound.id, $0) }
                .emit(to: viewModel.sceneVolume)
                .disposed(by: disposeBag)
        }
        
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        
        let scrollToTop = scrollView.rx.didScroll
            .withLatestFrom(scrollView.rx.contentOffset)
            .map { -$0.y }
            .filter { $0 > 0 }
            .map { [weak self] y -> CGFloat? in
                guard let self = self else {
                    return nil
                }
                return self.view.frame.minY + y
            }
            .filter { $0 != nil }
            .map { $0! }
            .asSignal(onErrorSignalWith: .empty())
        
        let scrollToTopY = scrollToTop.filter { $0 < Constants.heightToDismiss && $0 > 0 }
        let shouldDismissByScroll = scrollToTop.filter { $0 >= Constants.heightToDismiss }
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
            .asSignal(onErrorSignalWith: .empty())
        
        let shouldDismissByPan = panEvent
            .filter { $0 >= Constants.heightToDismiss }
            .take(1)
        
        let shouldDismissByTap = tapGesture.rx.event
            .filter { $0.state == .ended }
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        let shouldDismiss = Signal
            .merge(
                shouldDismissByPan.map { _ in () },
                shouldDismissByScroll.map { _ in () }
            )
        
        shouldDismiss
            .emit(to: Binder(self) { base, _ in
                UIView.animate(
                    withDuration: 0.4,
                    animations: {
                        base.view.frame = .init(
                            x: 0,
                            y: base.view.frame.maxY,
                            width: base.view.frame.width,
                            height: base.view.frame.height
                        )
                    },
                    completion: { [weak self] _ in
                        self?.view.removeFromSuperview()
                        self?.removeFromParent()
                        RateManager.showRateController()
                    }
                )
            })
            .disposed(by: disposeBag)
        
        shouldDismissByTap
            .emit(to: Binder(self) { base, _ in
                UIView.animate(
                    withDuration: 1,
                    animations: {
                        base.blurView.effect = nil
                        base.randomView.alpha = 0
                        base.defaultView.alpha = 0
                        base.sleepTimerView.alpha = 0
                        base.sliderImageView.alpha = 0
                        base.stackView.alpha = 0
                    },
                    completion: { [weak self] _ in
                        self?.view.removeFromSuperview()
                        self?.removeFromParent()
                        RateManager.showRateController()
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let beingDismissed = shouldDismiss.map { _ in true }
        
        let panEventY = panEvent
            .filter { $0 < Constants.heightToDismiss && $0 > 0 }
            
        Signal
            .merge(
                panEventY,
                scrollToTopY
            )
            .withLatestFrom(beingDismissed.startWith(false)) { ($0, $1) }
            .filter { !$1 }
            .map { $0.0 }
            .emit(to: Binder(self) { base, y in
                base.view.frame = .init(
                    x: 0,
                    y: y,
                    width: base.view.frame.width,
                    height: base.view.frame.height
                )
            })
            .disposed(by: disposeBag)
        
        ControlEvent
            .merge(
                panGesture.rx.event.filter { $0.state == .ended }.map { _ in () },
                scrollView.rx.didEndDragging.map { [weak self] _ -> Bool in
                    guard let self = self else {
                        return false
                    }
                    return self.view.frame.minY > 0
                }
                .filter { $0 }
                .map { _ in () }
            )
            .withLatestFrom(beingDismissed.startWith(false))
            .filter { !$0 }
            .bind(to: Binder(self) { base, _ in
                UIView.animate(
                    withDuration: 0.4,
                    animations: {
                        base.view.frame = .init(
                            x: 0,
                            y: 0,
                            width: base.view.frame.width,
                            height: base.view.frame.height
                        )
                    }
                )
            })
            .disposed(by: disposeBag)
        
        return Output(didDismiss: Signal.merge(shouldDismiss.map { _ in () }, shouldDismissByTap))
    }
}

extension SceneSettingsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset.y = max(0, scrollView.contentOffset.y)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: true)
    }
}

private extension SceneSettingsViewController {
    
    enum Constants {
        static let heightToDismiss: CGFloat = 50
    }
}
