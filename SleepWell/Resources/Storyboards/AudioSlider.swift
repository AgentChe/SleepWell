//
//  AudioSlider.swift
//  SleepWell
//
//  Created by Alexander Mironov on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class AudioSlider: UISlider {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setThumbImage(thumbImage, for: .normal)
    }
    
    private lazy var thumbImage: UIImage = {
        let radius = CGFloat(8)
        let thumb = UIView()
        thumb.backgroundColor = .white
        thumb.frame = .init(x: 0, y: radius / 2, width: radius, height: radius)
        thumb.layer.cornerRadius = radius / 2
        let renderer = UIGraphicsImageRenderer(size: thumb.bounds.size)
        let image = renderer.image { _ in
            thumb.drawHierarchy(in: thumb.bounds, afterScreenUpdates: true)
        }
        return image
    }()
}

extension Reactive where Base: UISlider {
    
    var setValue: Binder<Float> {
        return Binder(base) { base, value in
            if !base.isTracking {
                base.value = value
            }
        }
    }
    
    var userSetsValue: Signal<Float> {
        return base.rx.value
            .asSignal(onErrorSignalWith: .empty())
            .flatMapLatest { [base] value -> Signal<Float> in
                guard !base.isTracking else {
                    return .empty()
                }
                return .just(value)
            }
            .debounce(.milliseconds(50))
    }
}
