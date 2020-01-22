//
//  ViewportView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 12/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewportView: UIView {
    
    typealias Volume = (to: Int, volume: Float)

    @IBOutlet private var louderLabel: UILabel!
    @IBOutlet private var hushLabel: UILabel!
    @IBOutlet private var weakerLabel: UILabel!
    @IBOutlet private var strongerLabel: UILabel!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var addButton: UIButton!
    @IBOutlet private var deleteArea: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        setupUI()
        setupRx()
    }
    
    private func setupUI() {
        UINib(nibName: "ViewportView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        addSubview(containerView)
        
        [
            louderLabel,
            hushLabel,
            weakerLabel,
            strongerLabel
        ].forEach {
            $0?.alpha = 0
        }
        
        deleteArea.alpha = 0
        
        trashContainerPath = scalePath
        
        weakerLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        strongerLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
    }
    
    private func setupRx() {
        let sounds = noiseSounds
            .compactMap { $0 }
            .scan([Noise]()) { old, new in
                var result = old
                result.append(new)
                return result
            }
        
        let addNoiseView = noiseSounds
            .delay(.milliseconds(550), scheduler: MainScheduler.instance)
            .compactMap(setupNoiseView)
        
        let noiseViews = Observable
            .merge(deletedRelay.compactMap { $0 }, addNoiseView)
            .scan([NoiseView]()) { [weak self] old, action -> [NoiseView] in
                guard let self = self else { return old }
                var result = old
                switch action {
                case let .add(view):
                    guard !result.contains(where: { $0.id == view.id }) else {
                        return old
                    }
                    result.append(view)
                    self.addSubview(view)
                case let .delete(id):
                    guard let view = result.first(where: { $0.id == id }) else {
                        return old
                    }
                    result.removeAll(where: { $0.id == id })
                    view.removeFromSuperview()
                }
                return result
            }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        
        let viewsTranslation = noiseViews
            .flatMap(changeVolumeAction)
            .share(replay: 1, scope: .whileConnected)
        
        viewsTranslation
            .withLatestFrom(sounds) { ($0, $1) }
            .compactMap { stub, noises -> (Bool, Bool)? in
                let count = noises.first(where: { $0.id == stub.0 })?.sounds.count ?? 1
                let isSingleSound = count == 1
                
                switch stub.1 {
                case .began(_), .touchBegan:
                    return (false, isSingleSound)
                case .ended(_):
                    return (true, isSingleSound)
                default:
                    return nil 
                }
            }
            .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
            .bind(to: borderAnimation)
            .disposed(by: disposeBag)
        
        viewsTranslation
            .withLatestFrom(noiseViews) { ($0, $1) }
            .compactMap { tuple, views -> (NoiseView.Action, NoiseView)? in
                guard let view = views.first(where: { $0.id == tuple.0 }) else {
                    return nil
                }
                return (tuple.1, view)
            }
            .bind(to: trashAndScaleAnimate)
            .disposed(by: disposeBag)
        
        viewsTranslation
            .compactMap { tuple -> Int? in
                guard case .ended = tuple.1 else {
                    return nil
                }
                return tuple.0                 
        }
        .withLatestFrom(noiseViews) { ($0, $1) }
        .compactMap { [weak self] id, views -> NoiseViewAction? in
            guard
                let self = self,
                let view = views.first(where: { $0.id == id })
               
            else { return nil }

            let imageCenter = view.convert(view.imageCenter, to: self.containerView)
            let deleteFrame = self.deleteArea.frame
            guard deleteFrame.contains(imageCenter) else { return nil }
            
            return .delete(id: id)
        }
        .bind(to: deletedRelay)
        .disposed(by: disposeBag)
        
        viewsTranslation
            .compactMap { value -> Bool? in
                switch value.1 {
                case .began:
                    return false
                case .ended:
                    return true
                default:
                    return nil
                }
            }
            .distinctUntilChanged()
            .bind(to: viewActionRelay)
            .disposed(by: disposeBag)
        
        viewsTranslation
            .withLatestFrom(sounds) { ($0, $1) }
            .flatMapLatest(calculateVolume)
            .distinctUntilChanged {
                ($0.0 == $1.0) && ($0.1 == $1.1)
            }
            .bind(to: changeVolumeRelay)
            .disposed(by: disposeBag)
    }
    
    // Страшные штуки
    
    private lazy var setupNoiseView: (Noise?) throws -> NoiseViewAction? = { [weak self] soundModel in
        guard let self = self, let model = soundModel else { return nil }
        // TODO: - Когда будут добавлены параметры в модель
//        let posX = (model.positionX ?? 50) * self.volumeFactor
//        let posY = (model.positionY ?? 50) * self.volumeValue
                                    
            let posX = 50 * self.volumeFactor
            let posY = 50 * self.volumeValue
            let noiseView = NoiseView(frame: CGRect(origin: .zero, size: CGSize(width: 76, height: 120)))
            noiseView.setStartPosition(point: CGPoint(x: posX, y: posY))
            noiseView.setup(noise: model)
                
            return .add(view: noiseView)
        }
    
    private lazy var changeVolumeAction: ([NoiseView]) throws -> Observable<(Int, NoiseView.Action)> = { views in
        return Observable
            .from(views)
            .flatMap { view -> Observable<(Int, NoiseView.Action)> in
                guard let id = view.id else {
                    return .empty()
                }
                
                return view.centerView
                    .map { (id, $0) }
            }
    }
    
    private lazy var calculateVolume: ((Int, NoiseView.Action), [Noise]) throws -> Observable<Volume> = { [weak self] args, sounds in
        let (id, action) = args
        guard let self = self else { return .empty() }
        switch action {
        case let .changed(center, width):
            let posY = floor(center.y > self.containerView.center.y ? center.y + width / 2 : center.y - width / 2)
            let posX = floor(center.x > self.containerView.center.x ? center.x + width / 2 : center.x - width / 2)
            let volume = Float(round((1 - posY / 100 / self.volumeValue) * 100) / 100)
            let factor = Float(round((1 - posX / 100 / self.volumeFactor) * 100) / 100)
            let ids = sounds.first(where: { $0.id == id })?.sounds.map { $0.id } ?? []
            
            guard ids.count != 0 || ids.count == 2 else {
                return .empty()
            }
            
            guard ids.count > 1 else {
                return .just((to: ids.first!, volume: volume))
            }
            let weakerVolume = volume * (1 - factor)
            let strongerVolume = volume * factor
            return Observable.merge(.just((to: ids.first!, volume: weakerVolume)), .just((to: ids.last!, volume: strongerVolume)))
        default:
            return .empty()
        }
    }
    
    private let deletedRelay = BehaviorRelay<NoiseViewAction?>(value: nil)
    private var trashContainerPath: UIBezierPath!
    private let minScale: CGFloat = 0.8
    private let maxScale: CGFloat = 1.5
    private let viewActionRelay = PublishRelay<Bool>()
    private let changeVolumeRelay = PublishRelay<Volume>()
    private let noiseSounds = BehaviorRelay<Noise?>(value: nil)
    private let disposeBag = DisposeBag()
}

extension ViewportView {
    
    var changeVolume: Signal<(to: Int, volume: Float)> {
        return changeVolumeRelay.asSignal()
    }
    
    var didMovingView: Signal<Bool> {
        return viewActionRelay.asSignal().map { !$0 }
    }
    
    var item: Binder<Noise> {
        return Binder(self) { base, element in
            base.noiseSounds.accept(element)
        }
    }
    
    var didTapAdd: Signal<Void> {
        return addButton.rx.tap.asSignal()
    }
    
    var deletedSound: Observable<Int> {
        return deletedRelay
            .compactMap { action in
                guard case let .delete(id) = action else { return nil }
                return id
            }
    }
}

private extension ViewportView {
    
    enum NoiseViewAction {
        case add(view: NoiseView)
        case delete(id: Int)
    }
    
    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let distX = (from.x - to.x)
        let distY = (from.y - to.y)
        return sqrt((distX * distX) + (distY * distY))
    }

}

// Animations
private extension ViewportView {
    
    var borderAnimation: Binder<(isHidden: Bool, isSingleSound: Bool)> {
        return Binder(self) { base, stub in
            let (isHidden, isSingleSound) = stub
            
            var views = [base.hushLabel, base.louderLabel]
            if !isSingleSound {
                views.append(contentsOf: [
                    base.weakerLabel,
                    base.strongerLabel
                ])
            }
            
            UIView.animate(withDuration: 0.2) {
                views.forEach {
                    $0?.alpha = isHidden ? 0 : 1
                }
                
                base.addButton.alpha = !isHidden ? 0 : 1
            }
        }
    }
    
    var trashAndScaleAnimate: Binder<(NoiseView.Action, NoiseView)> {
        return Binder(self) { base, tuple in
            let (action, view) = tuple
            let imageCenter = view.convert(view.imageCenter, to: base.containerView)
            
            
            let minimumScale = base.deleteArea.bounds.size.width / view.imageSize.width
            
            let scale = base.animateNoiseScale(center: imageCenter, minimumScale: minimumScale, posY: imageCenter.y)
            
            switch action {
            case .touchBegan:
                let newScale = scale * 1.2
                UIView.animate(withDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: newScale, y: newScale)
                }
            case .ended:
                UIView.animate(withDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: scale, y: scale)
                    base.deleteArea.alpha = 0
                }
            default:
                base.deleteArea.alpha = base.animateTrashAlpha(posY: imageCenter.y)
                let newScale = scale * 1.2
                view.transform = CGAffineTransform(scaleX: newScale, y: newScale)
            }
        }
    }
    
    func animateNoiseScale(center: CGPoint, minimumScale: CGFloat, posY: CGFloat) -> CGFloat {
        if trashContainerPath.contains(center) {
            let scaleFactor = minScale - minimumScale
            
            let distanceForTrash = distance(from: center, to: trashCenter)
            let scale = minimumScale + distanceForTrash / trashScaleRadius * scaleFactor
            
            guard scale >= minimumScale else {
                return minimumScale
            }
            
            guard scale <= minScale else {
                return minScale
            }
            
            return scale
        } else {
            let scaleFactor = 1 - (maxScale - minScale) / (containerView.bounds.height)
            let scale = maxScale - (posY - trashScaleRadius) / (containerView.bounds.height) * scaleFactor
            
            guard scale >= minScale else {
                return minScale
            }
            
            guard scale <= maxScale else {
                return maxScale
            }
            
            return scale
        }
    }
    
    func animateTrashAlpha(posY: CGFloat) -> CGFloat {
        let thirdOfScreen = containerView.bounds.height / 3
        let areaY = containerView.bounds.height - thirdOfScreen
        guard posY > areaY else {
            return 0
        }
        
        let alphaFactor = 1 / thirdOfScreen
        let alpha = 1 - (containerView.bounds.height - posY) * alphaFactor
        return alpha
    }
}

private extension ViewportView {
    
    private var volumeValue: CGFloat {
        containerView.bounds.height / 100
    }
    
    private var volumeFactor: CGFloat {
        containerView.bounds.width / 100
    }
    
    private var trashCenter: CGPoint {
        deleteArea.center
    }
    
    private var trashScaleRadius: CGFloat {
        return 100
    }
    
    private var scalePath: UIBezierPath {
        return UIBezierPath(
            arcCenter: deleteArea.center,
            radius: trashScaleRadius,
            startAngle: 0,
            endAngle: 2 * CGFloat.pi,
            clockwise: true)
    }
}
