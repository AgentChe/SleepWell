//
//  SceneVideoCell.swift
//  SleepWell
//
//  Created by Alexander Mironov on 13/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//


import AVFoundation
import RxCocoa
import RxSwift
import UIKit

final class SceneVideoCell: UICollectionViewCell {
    
    func setup(model: SceneCellModelFields) {
        let player = AVPlayer(playerItem: AVPlayerItem(url: model.url))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)
        player.play()
        
        disposeBag = DisposeBag()
        
        NotificationCenter.default.rx
            .notification(
                .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
            .bind(to: Binder(player) { player, _ in
                player.seek(to: CMTime.zero)
                player.play()
            })
            .disposed(by: disposeBag)
    }
    
    private var disposeBag = DisposeBag()
}
