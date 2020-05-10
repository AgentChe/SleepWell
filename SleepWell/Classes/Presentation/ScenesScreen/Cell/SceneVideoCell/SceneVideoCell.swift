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
    
    private lazy var placeholderImageView = makePlaceholderImageView()
    
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(model: SceneCellModelFields, didBecomeActive: Signal<Void>) {
        placeholderImageView.isHidden = false
        placeholderImageView.kf.cancelDownloadTask()
        placeholderImageView.kf.setImage(with: URL(string: model.placeholderUrl))
        
        player = AVQueuePlayer()
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer.insertSublayer(playerLayer, at: 0)
        
        playerItem = AVPlayerItem(url: model.url.localUrl)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.initial, .new], context: nil)
        
        player.play()
        
        didBecomeActive
            .emit(to: Binder(self) { cell, _ in
                if cell.player.rate != 1 {
                    cell.player.play()
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "readyForDisplay", playerLayer?.isReadyForDisplay == true {
            placeholderImageView.isHidden = true
        }
    }
    
    // MARK: Make constraints
    
    private func makeConstraints() {
        NSLayoutConstraint.activate([
            placeholderImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            placeholderImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            placeholderImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: Lazy initialzation
    
    private func makePlaceholderImageView() -> UIImageView {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        return view
    }
}
