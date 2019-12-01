//
//  MiniPlayerView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 25/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MiniPlayerView: UIView {
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var nameTrack: UILabel!
    @IBOutlet private var widthConstraint: NSLayoutConstraint!
    @IBOutlet private var nameLeftConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        UINib(nibName: "MiniPlayerView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        addSubview(containerView)
    }
    
    var playerIsHidden = false {
        didSet {
            self.widthConstraint.constant = self.playerIsHidden ? 17.25 : 25.55
            self.nameLeftConstraint.constant = self.playerIsHidden ? 60 : 24.8
        }
    }

    var isPlaying = false {
        didSet {
            let image = isPlaying ? UIImage(named: "scene_pause_button") : UIImage(named: "play_scene_button")
            playButton.setImage(image, for: .normal)
        }
    }
    
    var name: String? {
        didSet {
            nameTrack.text = name
        }
    }
}

extension MiniPlayerView {
    var didTapPlay: Signal<PlayerAction> {
        return playButton.rx.tap
            .compactMap { [weak self] _  -> PlayerAction? in
                guard let self = self else { return nil }
                if self.playerIsHidden {
                    return .show
                } else if self.isPlaying {
                    self.isPlaying = !self.isPlaying
                    return .pause
                } else {
                    self.isPlaying = !self.isPlaying
                    return .play
                }
            }
            .asSignal(onErrorSignalWith: .never())
    }
}

extension MiniPlayerView {
    enum PlayerAction {
        case play, pause, show
    }
}
