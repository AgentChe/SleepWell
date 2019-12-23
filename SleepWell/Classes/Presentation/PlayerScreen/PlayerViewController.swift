//
//  PlayerViewController.swift
//  SleepWell
//
//  Created by Alexander Mironov on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class PlayerViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var playerImageView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var audioSlider: AudioSlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    private let disposeBag = DisposeBag()
}

extension PlayerViewController: BindsToViewModel {
    typealias ViewModel = PlayerViewModel
    
    struct Input {
        let recording: RecordingDetail
        let hideTabbarClosure: (Bool) -> Void
        let didStartPlaying: (String) -> Void
        let didPause: () -> Void
    }
    
    static func make() -> PlayerViewController {
        let storyboard = UIStoryboard(name: "PlayerScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "PlayerViewController")
            as! PlayerViewController
    }
    
    func bind(to viewModel: PlayerViewModelInterface, with input: Input) {
        
        
        
        [backgroundImageView, blurView].forEach {
            $0.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        
        if let imagePreview = input.recording.recording.imagePreviewUrl {
            backgroundImageView.kf.indicatorType = .activity
            backgroundImageView.kf.setImage(with: imagePreview, options: [.transition(.fade(0.2))])
            
            playerImageView.kf.indicatorType = .activity
            playerImageView.kf.setImage(with: imagePreview, options: [.transition(.fade(0.2))])
        }
        
        titleLabel.text = input.recording.recording.name
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
        
        let heightToDismiss: CGFloat = 75
        
        let beingDismissed = panEvent.filter { $0 >= heightToDismiss }
            .take(1)
        
        let isCurrentRecordingPlaying = viewModel.isPlaying(recording: input.recording)

        isCurrentRecordingPlaying
            .drive(rx.playingState)
            .disposed(by: disposeBag)
        
        beingDismissed.map { _ in false }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: input.hideTabbarClosure)
            .disposed(by: disposeBag)
        
        beingDismissed
            .withLatestFrom(isCurrentRecordingPlaying)
            .filter { $0 }
            .bind(to: Binder(self) { _, _ in
                RateManager.showRateController()
            })
            .disposed(by: disposeBag)
        
        subtitleLabel.text = input.recording.recording.reader
        
        rx.methodInvoked(#selector(UIViewController.viewWillAppear))
            .take(1)
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: Binder(self) { base, _ in
                let maxY = UIScreen.main.bounds.maxY
                UIView.performWithoutAnimation {
                    base.topConstraint.constant = maxY
                    base.bottomConstraint.constant = -maxY
                    base.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        rx.methodInvoked(#selector(UIViewController.viewDidAppear))
            .take(1)
            .asSignal(onErrorSignalWith: .empty())
            .map { _ in Constants.marginTop }
            .emit(to: rx.updateViewPosition)
            .disposed(by: disposeBag)

        panGesture.rx.event
            .filter { $0.state == .ended }
            .withLatestFrom(beingDismissed.map { _ in true }.startWith(false))
            .filter { !$0 }
            .map { _ in Constants.marginTop }
            .bind(to: rx.updateViewPosition)
            .disposed(by: disposeBag)

        panEvent
            .filter { $0 < heightToDismiss && $0 > 0 }
            .withLatestFrom(beingDismissed.map { _ in true }.startWith(false)) { ($0, $1) }
            .filter { !$1 }
            .map { $0.0 }
            .asSignal(onErrorSignalWith: .empty())
            .emit(to: Binder(self) { base, panY in
                let y = panY + Constants.marginTop
                base.topConstraint.constant = y
                base.bottomConstraint.constant = -panY
            })
            .disposed(by: disposeBag)
        
        beingDismissed
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
                    completion: { [weak self] _ in
                        self?.view.removeFromSuperview()
                        self?.removeFromParent()
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let maxSeconds = input.recording.readingSound.soundSecs
        
        let didTapPlayButton = playButton.rx.tap
            .asSignal()
        
        didTapPlayButton
            .flatMapFirst {
                Signal
                    .zip(
                        viewModel.add(recording: input.recording),
                        viewModel.pauseScene(style: .force),
                        viewModel.pauseRecording(style: .force)
                    )
                    .take(1)
            }
            .flatMapLatest { _ in viewModel.playRecording(style: .force) }
            .emit()
            .disposed(by: disposeBag)
        
        let didTapPauseButton = pauseButton.rx.tap
            .asSignal()
        
        didTapPauseButton.emit(onNext: input.didPause)
            .disposed(by: disposeBag)
        
        didTapPauseButton.map { _ in .force }
            .flatMapFirst { viewModel.pauseRecording(style: $0) }
            .emit()
            .disposed(by: disposeBag)
        
        beingDismissed.asSignal(onErrorSignalWith: .empty())
            .take(1)
            .withLatestFrom(Signal.merge(didTapPlayButton, didTapPauseButton))
            .withLatestFrom(isCurrentRecordingPlaying)
            .filter { $0 }
            .map { _ in input.recording.recording.name }
            .emit(onNext: input.didStartPlaying)
            .disposed(by: disposeBag)
        
        let currentSeconds = viewModel.time(for: input.recording.recording.id)
            .startWith(0)
        
        currentSeconds.map { $0.timeDescription }
            .drive(currentTimeLabel.rx.text)
            .disposed(by: disposeBag)
        
        currentSeconds.map { "-" + (max(maxSeconds - $0, 0)).timeDescription }
            .drive(remainingTimeLabel.rx.text)
            .disposed(by: disposeBag)
        
        currentSeconds
            .map { value -> Float in
                guard value != 0 else {
                    return 0.0
                }
                return Float(value) / Float(maxSeconds)
            }
            .drive(audioSlider.rx.setValue)
            .disposed(by: disposeBag)
        
        currentSeconds.filter { $0 >= maxSeconds }
            .map { _ in () }
            .drive(viewModel.resetAudio)
            .disposed(by: disposeBag)
        
        audioSlider.rx.userSetsValue
            .map { Int(round($0 * Float(maxSeconds))) }
            .emit(to: viewModel.setTime)
            .disposed(by: disposeBag)
        
        fastForwardButton.rx.tap
            .asSignal()
            .withLatestFrom(currentSeconds)
            .map { min($0 + 15, maxSeconds) }
            .emit(to: viewModel.setTime)
            .disposed(by: disposeBag)
        
        rewindButton.rx.tap
            .asSignal()
            .withLatestFrom(currentSeconds)
            .map { max($0 - 15, 0) }
            .emit(to: viewModel.setTime)
            .disposed(by: disposeBag)
        
        volumeButton.rx.tap
            .asSignal()
            .map { input.recording }
            .emit(onNext: viewModel.goToVolumeScreen)
            .disposed(by: disposeBag)
    }
}

private extension Reactive where Base: PlayerViewController {
    
    var playingState: Binder<Bool> {
        
        Binder(base) { base, state in
            
            let stateAlpha: CGFloat = state ? 1 : 0
            
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    base.playButton.alpha = 1 - stateAlpha
                    base.pauseButton.alpha = stateAlpha
                }
            )
        }
    }
    
    var updateViewPosition: Binder<CGFloat> {
        
        Binder(base) { base, y in
            base.topConstraint.constant = y
            base.bottomConstraint.constant = 0
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    base.view.layoutIfNeeded()
                }
            )
        }
    }
}

private enum Constants {
    static let marginTop: CGFloat = 49
}

private extension Int {
    
    var timeDescription: String {
        
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        let hoursString = hours == 0 ? "" : "\(hours):"
        let secondsString = seconds < 10
            ? "0\(seconds)"
            : String(seconds)
        
        return "\(hoursString)\(minutes):\(secondsString)"
    }
}
