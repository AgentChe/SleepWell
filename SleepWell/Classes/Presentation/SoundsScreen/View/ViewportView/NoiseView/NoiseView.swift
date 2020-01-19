//
//  NoiseView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 12/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension NoiseView {
    
    enum Action {
        case began(CGPoint)
        case changed(CGPoint)
        case ended(CGPoint)
    }
}

class NoiseView: UIView {

    @IBOutlet private var name: UILabel!
    @IBOutlet private var image: UIImageView!
    @IBOutlet private var containerView: UIView!
    
    var imageSize: CGFloat {
        return image.bounds.width
    }
    
    var imageCenter: CGPoint {
        return image.center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        UINib(nibName: "NoiseView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        
        addSubview(containerView)
        name.isHidden = true
        
        image.addGestureRecognizer(panGesture)
    }
    
    func setup(noise: Noise) {
        id = noise.id
        image.kf.setImage(with: noise.imageUrl, options: [.transition(.fade(0.2))])
        name.text = noise.name
    }
    
    func setStartPosition(point: CGPoint) {
        center = moving(to: point)
    }

    private func moving(to newCenter: CGPoint) -> CGPoint {
        let currentCenter = center
        center.x = newCenter.x

        let rect1 = image.convert(image.bounds, to: superview)
        if superview?.bounds.contains(rect1) == false {
            center.x = currentCenter.x
        }
        
        center.y = newCenter.y

        let rect2 = image.convert(image.bounds, to: superview)
        if superview?.bounds.contains(rect2) == false {
            center.y = currentCenter.y
        }
        
        return center
    }
    
    private lazy var panHandler: (UIPanGestureRecognizer) throws -> Action? = { [weak self] gesture in
        guard let self = self else {
            return nil
        }
        let translation = gesture.translation(in: self.superview)
        let center = self.center
        let newCenter = CGPoint(x: self.lastCenter.x + translation.x , y: self.lastCenter.y + translation.y)
        switch gesture.state {
        case .began:
            self.superview?.bringSubviewToFront(self)
            self.lastCenter = center
            self.name.isHidden = false
            return .began(center)
        case .changed:
            return .changed(self.moving(to: newCenter))
        case .ended:
            self.name.isHidden = true
            return .ended(self.moving(to: newCenter))
        default:
            return nil
        }
    }
    
    private var lastCenter: CGPoint = .zero
    private let disposeBag = DisposeBag()
    private let panGesture = UIPanGestureRecognizer()
    private(set) var id: Int?
}

extension NoiseView {
    
    var centerView: Observable<Action> {
        return panGesture.rx.event.compactMap(panHandler)
    }
}
