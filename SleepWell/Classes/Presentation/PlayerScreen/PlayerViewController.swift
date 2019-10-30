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
    
    private let disposeBag = DisposeBag()
}

extension PlayerViewController: BindsToViewModel {
    typealias ViewModel = PlayerViewModel
    
    struct Input {
        let recording: RecordingDetail
    }
    
    static func make() -> PlayerViewController {
        let storyboard = UIStoryboard(name: "PlayerScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "PlayerViewController")
            as! PlayerViewController
    }
    
    func bind(to viewModel: PlayerViewModelInterface, with input: Input) {
        
        if let imagePreview = input.recording.recording.imagePreviewUrl,
            let data = try? Data(contentsOf: imagePreview) {
            
            backgroundImageView.image = UIImage(data: data)
            playerImageView.image = UIImage(data: data)
        }
        
        titleLabel.text = input.recording.recording.name
        
        rx.methodInvoked(#selector(UIViewController.viewDidDisappear))
            .take(1)
            .map { _ in () }
            .bind(to: viewModel.stop)
            .disposed(by: disposeBag)
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
        
        let heightToDissmiss = view.frame.height / 3
        
        let beingDissmissed = panEvent.filter { $0 >= heightToDissmiss }
            .take(1)
        
        let isPlaying = viewModel.isPlaying
        
        isPlaying
            .drive(rx.playingState)
            .disposed(by: disposeBag)
        
        let subtitleWithDuration = input.recording.recording.reader
            + " · "
            + input.recording.readingSound.soundSecs.subtitleDescription
        
        isPlaying.map {
            $0 ? input.recording.recording.reader : subtitleWithDuration
        }
        .drive(subtitleLabel.rx.text)
        .disposed(by: disposeBag)
        
        let viewWillLayoutSubviews = rx.methodInvoked(#selector(UIViewController.viewWillLayoutSubviews))
            .take(1)
            .map { _ in false }
        
        let skippingIsPlaying = isPlaying.asObservable()
            .skipUntil(viewWillLayoutSubviews)
        
        let yPosition = Observable
            .merge(skippingIsPlaying, viewWillLayoutSubviews)
            .distinctUntilChanged()
            .map { [weak self] state -> CGFloat in
                guard let self = self, !state else {
                    return 0
                }

                let screenHeight = UIScreen.main.bounds.height
                let lastViewY = self.pauseButton.frame.maxY
                let viewHeight = lastViewY + CGFloat(28)
                return screenHeight - viewHeight
            }
            .asDriver(onErrorDriveWith: .empty())
        
        yPosition.drive(rx.updateViewPosition)
            .disposed(by: disposeBag)
        
        panGesture.rx.event
            .filter { $0.state == .ended }
            .withLatestFrom(beingDissmissed.map { _ in true }.startWith(false))
            .filter { !$0 }
            .withLatestFrom(yPosition)
            .bind(to: Binder(self) { base, y in
                UIView.animate(withDuration: 0.5, animations: {
                    base.view.frame = .init(
                        x: base.view.frame.minX,
                        y: y,
                        width: base.view.frame.width,
                        height: base.view.frame.height
                    )
                })
            })
            .disposed(by: disposeBag)
        
        panEvent
            .filter { $0 < heightToDissmiss && $0 > 0 }
            .withLatestFrom(beingDissmissed.map { _ in true }.startWith(false)) { ($0, $1) }
            .filter { !$1 }
            .map { $0.0 }
            .withLatestFrom(yPosition) { $0 + $1 }
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
                        viewModel.dismiss()
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let maxSeconds = input.recording.readingSound.soundSecs
        viewModel.add(recording: input.recording)
        
        playButton.rx.tap
            .asSignal()
            .emit(to: viewModel.play)
            .disposed(by: disposeBag)
        
        pauseButton.rx.tap
            .asSignal()
            .emit(to: viewModel.reset)
            .disposed(by: disposeBag)
        
        isPlaying
            .asSignal(onErrorSignalWith: .empty())
            .filter { !$0 }
            .map { _ in () }
            .emit(to: viewModel.reset)
            .disposed(by: disposeBag)
        
        let currentSeconds = viewModel.time
        
        currentSeconds.map { $0.timeDescription }
            .drive(currentTimeLabel.rx.text)
            .disposed(by: disposeBag)
        
        currentSeconds.map { "-" + (maxSeconds - $0).timeDescription }
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
        
        audioSlider.rx.userSetsValue
            .map { Double($0 * Float(maxSeconds)) }
            .emit(to: viewModel.setTime)
            .disposed(by: disposeBag)
        
        fastForwardButton.rx.tap
            .asSignal()
            .withLatestFrom(currentSeconds)
            .map { min($0 + 15, maxSeconds) }
            .map(Double.init)
            .emit(to: viewModel.setTime)
            .disposed(by: disposeBag)
        
        rewindButton.rx.tap
            .asSignal()
            .withLatestFrom(currentSeconds)
            .map { max($0 - 15, 0) }
            .map(Double.init)
            .emit(to: viewModel.setTime)
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
                    
                    [base.currentTimeLabel,
                     base.remainingTimeLabel,
                     base.rewindButton,
                     base.pauseButton,
                     base.fastForwardButton,
                     base.audioSlider,
                     base.volumeButton
                    ].forEach { $0.alpha = stateAlpha }
                }
            )
        }
    }
    
    var updateViewPosition: Binder<CGFloat> {
        
        Binder(base) { base, y in
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    base.view.frame = .init(
                        x: base.view.frame.minX,
                        y: y,
                        width: base.view.frame.width,
                        height: base.view.frame.height
                    )
                }
            )
        }
    }
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
    
    var subtitleDescription: String {
        
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        guard hours != 0 else {
            return "\(minutes) min"
        }
        
        guard minutes != 0 else {
            return "\(hours) hours"
        }
        
        return "\(hours) hours \(minutes) min"
    }
}
