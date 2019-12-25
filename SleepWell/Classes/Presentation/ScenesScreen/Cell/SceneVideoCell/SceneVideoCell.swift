//
//  SceneVideoCell.swift
//  SleepWell
//
//  Created by Alexander Mironov on 13/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//


import AVFoundation
import UIKit
import RxSwift
import RxCocoa

final class SceneVideoCell: UICollectionViewCell {
    private var player: AVQueuePlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var playerLooper: AVPlayerLooper!
    
    func setup(model: SceneCellModelFields, didBecomeActive: Signal<Void>) {
        player = AVQueuePlayer()
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)
        
        playerItem = AVPlayerItem(url: model.url.localUrl)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        player.play()
        
        didBecomeActive
            .emit(to: Binder(self) { cell, _ in
                if cell.player.rate != 1 {
                    cell.player.play()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private let disposeBag = DisposeBag()
}
