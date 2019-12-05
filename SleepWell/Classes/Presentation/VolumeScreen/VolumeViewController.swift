//
//  VolumeViewController.swift
//  SleepWell
//
//  Created by Alexander Mironov on 10/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class VolumeViewController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var voiceVolumeSlider: VolumeSliderView!
    @IBOutlet weak var ambientVolumeSlider: VolumeSliderView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    private let disposeBag = DisposeBag()
}

extension VolumeViewController: BindsToViewModel {
    typealias ViewModel = VolumeViewModel

    struct Input {
        let recording: RecordingDetail
    }

    static func make() -> VolumeViewController {
        let storyboard = UIStoryboard(name: "VolumeScreen", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "VolumeViewController")
            as! VolumeViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

    func bind(to viewModel: VolumeViewModelInterface, with input: Input) {
        
        if let imagePreview = input.recording.recording.imagePreviewUrl {
            backgroundImageView.kf.indicatorType = .activity
            backgroundImageView.kf.setImage(with: imagePreview, options: [.transition(.fade(0.2))])
        }
        
        let isAmbiendSoundAvailable = input.recording.ambientSound != nil
        
        ambientVolumeSlider.isHidden = !isAmbiendSoundAvailable
        
        let currentMainPlayerVolume = viewModel.currentMainPlayerVolume ?? 0.0
        let currentAmbientPlayerVolume = viewModel.currentAmbientPlayerVolume ?? 0.0

        voiceVolumeSlider.configure(input: .init(
            text: "Voice",
            initialValue: currentMainPlayerVolume
        ))
        
        if isAmbiendSoundAvailable {
            ambientVolumeSlider.configure(input: .init(
                text: "Ambient",
                initialValue: currentAmbientPlayerVolume
            ))
        }
        
        voiceVolumeSlider.volume
            .emit(to: viewModel.mainPlayerVolume)
            .disposed(by: disposeBag)
        
        ambientVolumeSlider.volume
            .emit(to: viewModel.ambientPlayerVolume)
            .disposed(by: disposeBag)
        
        tapGesture.delegate = self
        
        tapGesture.rx.event
            .asSignal()
            .emit(onNext: { _ in
                viewModel.dismiss()
            })
            .disposed(by: disposeBag)
    }
}

extension VolumeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        touch.view == backgroundView
    }
}
