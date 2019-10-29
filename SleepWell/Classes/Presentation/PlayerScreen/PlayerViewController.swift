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
    
    @IBOutlet weak var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var audioSlider: AudioSlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    
    var input: Input!
    var viewModel: PlayerViewModelInterface!
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
        
        self.input = input
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //firstInit
        [currentTimeLabel,
         remainingTimeLabel,
         rewindButton,
         pauseButton,
         fastForwardButton,
         audioSlider,
         volumeButton
        ].forEach { $0.alpha = 0 }
        
        
        //doesnt work for unknown reason
        let screenHeight = UIScreen.main.bounds.height
        let viewHeight = pauseButton.frame.maxY + CGFloat(28)
        view.frame = .init(
            x: view.frame.minX,
            y: screenHeight - viewHeight,
            width: view.frame.width,
            height: view.frame.height
        )
        
        let panEvent = panGesture.rx.event
            .filter { $0.state == .changed }
            .map { [view] pan in
                pan.translation(in: view).y
            }
        
        let heightToDissmiss = view.frame.height / 3
        
        let beingDissmissed = panEvent.filter { $0 >= heightToDissmiss }
            .take(1)
        
        let isPlaying = Signal
            .merge(
                playButton.rx.tap.asSignal().map { true },
                pauseButton.rx.tap.asSignal().map { false }
            )
            .asDriver(onErrorDriveWith: .empty())
        
        isPlaying
            .drive(rx.playingState)
            .disposed(by: disposeBag)
        
        let yPosition = isPlaying.map { [weak self] state -> CGFloat in
            guard let self = self, !state else {
                return 0
            }

            let screenHeight = UIScreen.main.bounds.height
            let lastViewY = self.pauseButton.frame.maxY
            let viewHeight = lastViewY + CGFloat(28)
            return screenHeight - viewHeight
        }
        
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
                        base.removeFromParent()
                    }
                )
            })
            .disposed(by: disposeBag)
        
        let url = input.recording.readingSound.soundUrl
        let maxSeconds = 255
        viewModel.add(url: url)
        
        playButton.rx.tap
            .asSignal()
            .emit(to: viewModel.play)
            .disposed(by: disposeBag)
        
        pauseButton.rx.tap
            .asSignal()
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
        let seconds = self % 60
        
        let hoursString = hours == 0 ? "" : "\(hours):"
        let secondsString = seconds < 10
            ? "0\(seconds)"
            : String(seconds)
        
        return "\(hoursString)\(self / 60):\(secondsString)"
    }
}
