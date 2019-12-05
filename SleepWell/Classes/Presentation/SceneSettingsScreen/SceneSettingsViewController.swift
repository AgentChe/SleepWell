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
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var defaultView: UIView!
    @IBOutlet weak var randomView: UIView!
    @IBOutlet weak var sleepTimerView: UIView!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    
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
        
        if let image = input.sceneDetail.scene.imageUrl {
            backgroundImageView.kf.indicatorType = .activity
            backgroundImageView.kf.setImage(with: image, options: [.transition(.fade(0.2))])
        }
        
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
            })
            .disposed(by: disposeBag)
        
        let defaultTapGesture = UITapGestureRecognizer()
        defaultView.addGestureRecognizer(defaultTapGesture)
        let defaultVolumes = defaultTapGesture.rx.event.asSignal()
            .map { _ in Float(0.75) }
        
        let randomTapGesture = UITapGestureRecognizer()
        randomView.addGestureRecognizer(randomTapGesture)
        let randomVolumes = randomTapGesture.rx.event.asSignal()
        
        let sleepTimerTapGesture = UITapGestureRecognizer()
        sleepTimerView.addGestureRecognizer(sleepTimerTapGesture)
        sleepTimerTapGesture.rx.event.asSignal()
            .map { _ in input.sceneDetail }
            .emit(onNext: viewModel.showSleepTimerScreen)
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
        
        
        let heightToDissmiss = view.frame.height / 4
        
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
        
        let scrollToTopY = scrollToTop.filter { $0 < heightToDissmiss && $0 > 0 }
        let shouldDismissByScroll = scrollToTop.filter { $0 >= heightToDissmiss }
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
            .asSignal(onErrorSignalWith: .empty())
        
        let shouldDismissByPan = panEvent
            .filter { $0 >= heightToDissmiss }
            .take(1)
        
        let shouldDismiss = Signal
            .merge(
                shouldDismissByPan,
                shouldDismissByScroll
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
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let beingDismissed = shouldDismiss.map { _ in true }
        
        let panEventY = panEvent
            .filter { $0 < heightToDissmiss && $0 > 0 }
            
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
        
        return Output(didDismiss: shouldDismiss.map { _ in () })
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
