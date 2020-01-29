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
        case touchBegan
        case touchCancelled
        case began(CGPoint)
        case changed(CGPoint, CGFloat)
        case ended(CGPoint)
    }
}

class NoiseView: UIView {

    @IBOutlet private var name: UILabel!
    @IBOutlet private var image: UIImageView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var loadingView: LoadingView!
    
    var imageSize: CGSize {
        return image.bounds.size
    }
    
    var imageCenter: CGPoint {
        return image.center
    }
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                loadingView.layer.cornerRadius = image.frame.width / 2
                loadingView.start()
            } else {
                loadingView.stop()
            }
            
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first, image.frame.contains(touch.location(in: self)) {
            didTouch.accept(.touchBegan)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if let touch = touches.first, image.frame.contains(touch.location(in: self)) {
            didTouch.accept(.touchCancelled)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func setup(noise: Noise) {
        id = noise.id
        image.kf.setImage(with: noise.imageUrl, options: [.transition(.fade(0.2))])
        name.text = noise.name
    }
    
    func setStartPosition(point: CGPoint) {
        center = moving(to: point)
    }

    private func initialize() {
        UINib(nibName: "NoiseView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        
        addSubview(containerView)
        name.isHidden = true
        image.addGestureRecognizer(panGesture)
        loadingView.percentage = 0.12
        loadingView.backgroundColor = .clear
        loadingView.tintColor = UIColor.black.withAlphaComponent(0.65)
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
        
        return self.containerView.convert(imageCenter, to: superview)
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
            return .changed(self.moving(to: newCenter), self.frame.size.width)
        case .ended:
            self.name.isHidden = true
            return .ended(self.moving(to: newCenter))
        default:
            return nil
        }
    }
    
    private var lastCenter: CGPoint = .zero
    private let disposeBag = DisposeBag()
    private let didTouch = PublishRelay<Action>()
    private let panGesture = UIPanGestureRecognizer()
    private(set) var id: Int?
}

extension NoiseView {
    
    var centerView: Observable<Action> {
        let panAction = panGesture.rx.event.compactMap(panHandler)
        let tapAction = didTouch
            .withLatestFrom(panAction.startWith(.touchBegan)) { ($0, $1) }
            .compactMap { tap, pan -> Action? in
                guard case .began = pan else {
                    return tap
                }
                return nil
            }
        return Observable.merge(panAction, tapAction)
    }
}
