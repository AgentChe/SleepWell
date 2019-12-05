//
//  SceneTimerViewController.swift
//  SleepWell
//
//  Created by Alexander Mironov on 29/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SceneTimerViewController: UIViewController {
    @IBOutlet weak var fifteenMinView: UIView!
    @IBOutlet weak var thirtyView: UIView!
    @IBOutlet weak var fortyFiveView: UIView!
    @IBOutlet weak var sixtyView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet var backgroundTap: UITapGestureRecognizer!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var cancelView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var timerDescriptionLabel: UILabel!
    
    private let disposeBag = DisposeBag()
}

extension SceneTimerViewController: BindsToViewModel {
    
    typealias ViewModel = SceneTimerViewModel

    struct Input {
        let sceneDetail: SceneDetail
    }

    static func make() -> SceneTimerViewController {
        let storyboard = UIStoryboard(name: "SceneTimerScreen", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SceneTimerViewController")
            as! SceneTimerViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

    func bind(to viewModel: SceneTimerViewModelInterface, with input: Input) {
        
        if let image = input.sceneDetail.scene.imageUrl {
            backgroundImageView.kf.indicatorType = .activity
            backgroundImageView.kf.setImage(with: image, options: [.transition(.fade(0.2))])
        }
        
        let fifteenMinTapGesture = UITapGestureRecognizer()
        fifteenMinView.addGestureRecognizer(fifteenMinTapGesture)
        fifteenMinTapGesture.rx.event.asSignal()
            .map { _ in 15 * 60 }
            .emit(to: viewModel.setTimer)
            .disposed(by: disposeBag)
        
        let thirtyMinTapGesture = UITapGestureRecognizer()
        thirtyView.addGestureRecognizer(thirtyMinTapGesture)
        thirtyMinTapGesture.rx.event.asSignal()
            .map { _ in 30 * 60 }
            .emit(to: viewModel.setTimer)
            .disposed(by: disposeBag)
        
        let fortyFiveMinTapGesture = UITapGestureRecognizer()
        fortyFiveView.addGestureRecognizer(fortyFiveMinTapGesture)
        fortyFiveMinTapGesture.rx.event.asSignal()
            .map { _ in 45 * 60 }
            .emit(to: viewModel.setTimer)
            .disposed(by: disposeBag)
        
        let sixtyMinTapGesture = UITapGestureRecognizer()
        sixtyView.addGestureRecognizer(sixtyMinTapGesture)
        sixtyMinTapGesture.rx.event.asSignal()
            .map { _ in 60 * 60 }
            .emit(to: viewModel.setTimer)
            .disposed(by: disposeBag)
        
        
        let cancelTapGesture = UITapGestureRecognizer()
        cancelView.addGestureRecognizer(cancelTapGesture)
        cancelTapGesture.rx.event.asSignal()
            .map { _ in () }
            .emit(to: viewModel.cancelTimer)
            .disposed(by: disposeBag)
        
        viewModel.isTimerRunning
            .drive(Binder(self) { base, isRunning in
                base.fifteenMinView.isHidden = isRunning
                base.thirtyView.isHidden = isRunning
                base.fortyFiveView.isHidden = isRunning
                base.sixtyView.isHidden = isRunning
                base.cancelView.isHidden = !isRunning
                base.timerLabel.isHidden = !isRunning
                base.timerDescriptionLabel.isHidden = !isRunning
            })
            .disposed(by: disposeBag)
        
        viewModel.timerSeconds
            .map { $0.timerDescription }
            //.map { "\($0 / 60):\($0 % 60)" }
            .drive(timerLabel.rx.text)
            .disposed(by: disposeBag)
        
        backgroundTap.rx.event.asSignal()
            .map { _ in () }
            .emit(onNext: viewModel.dismiss)
            .disposed(by: disposeBag)
    }
}

extension SceneTimerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        touch.view == backgroundView
    }
}

private extension Int {
    
    var timerDescription: String {

        let minutes = self / 60
        let seconds = self % 60
        
        let minutesString = minutes < 10
            ? "0\(minutes)"
            : String(minutes)
        let secondsString = seconds < 10
            ? "0\(seconds)"
            : String(seconds)
        
        return "\(minutesString):\(secondsString)"
    }
}
