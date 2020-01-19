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
    @IBOutlet private var trashContainerView: UIView!
    
    private var volumeValue: CGFloat {
        (containerView.bounds.height - 60) / 100
    }
    
    private var volumeFactor: CGFloat {
        (containerView.bounds.width - 38) / 100
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
        
        trashContainerPath = semicirclePath(rect: trashContainerView.frame)
        let mask = CAShapeLayer()
        mask.path = trashContainerPath.cgPath
        trashContainerView.layer.mask = mask
        
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
        
//        let noiseViews = noiseSounds
//            .delay(.milliseconds(550), scheduler: MainScheduler.instance)
//            .compactMap(setupNoiseView)
//            .scan([NoiseView]()) { old, new in
//                var result = old
//                result.append(new)
//                return result
//            }
        
        let addNoiseView = noiseSounds
            .delay(.milliseconds(550), scheduler: MainScheduler.instance)
            .compactMap { [weak self] soundModel -> NoiseViewAction? in
                    guard let self = self, let model = soundModel else {
                        return nil
                    }
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
        
        let testnoiseViews = Observable
            .merge(deletedRelay.compactMap { $0 }, addNoiseView)
            .scan([NoiseView]()) { [weak self] old, action -> [NoiseView] in
                guard let self = self else { return old }
                switch action {
                case let .add(view):
                    self.addSubview(view)
                    return old + [view]
                case let .delete(id):
                    var result = old
                    guard let view = result.first(where: { $0.id == id }) else {
                        return old
                    }
                    result.removeAll(where: { $0.id == id })
                    view.removeFromSuperview()
                    return result
                }
            }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        
        let viewsTranslation = testnoiseViews
            .flatMap(changeVolumeAction)
            .share(replay: 1, scope: .whileConnected)
        
        let viewActivity = viewsTranslation
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
            .share(scope: .whileConnected)
        
        viewsTranslation
            .compactMap { tuple -> Int? in
                guard case .ended = tuple.1 else {
                    return nil
                }
                return tuple.0
        }
        .withLatestFrom(testnoiseViews) { ($0, $1) }
        .compactMap { [weak self] id, views -> NoiseViewAction? in
            guard
                let self = self,
                let view = views.first(where: { $0.id == id })
               
            else { return nil }
            
            // Проверяем находится ли центр картинки звука внутри вьюхи корзины
            guard self.deleteArea.frame.contains(view.convert(view.imageCenter, to: self.deleteArea)) else {
                return nil }
            
            return .delete(id: id)
        }
        .bind(to: deletedRelay)
        .disposed(by: disposeBag)
        
        viewActivity
            .bind(to: viewActionRelay)
            .disposed(by: disposeBag)
            
        viewActivity
            .bind(to: borderAnimation)
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
    
    private lazy var setupNoiseView: (Noise?) throws -> NoiseView? = { [weak self] soundModel  in
        guard let self = self, let model = soundModel else {
            return nil
        }
        // TODO: - Когда будут добавлены параметры в модель
//        let posX = (model.positionX ?? 50) * self.volumeFactor
//        let posY = (model.positionY ?? 50) * self.volumeValue
                    
        let posX = 50 * self.volumeFactor
        let posY = 50 * self.volumeValue
        let noiseView = NoiseView(frame: CGRect(origin: .zero, size: CGSize(width: 76, height: 120)))
        noiseView.setStartPosition(point: CGPoint(x: posX, y: posY))
        noiseView.setup(noise: model)
        
        self.containerView.addSubview(noiseView)
        return noiseView
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
        case let .changed(center):
            let posY = center.y
            let posX = center.x
            let volume = Float(1 - posY / 100 / self.volumeValue)
            let factor = Float(1 - posX / 100 / self.volumeFactor)
            let ids = sounds.first(where: { $0.id == id })?.sounds.map { $0.id } ?? []
            print("volume: \(volume)")
            print("factor: \(factor)")
            
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
    
    var borderAnimation: Binder<Bool> {
        return Binder(self) { base, isHidden in
            UIView.animate(withDuration: 0.2) {
                [
                    base.louderLabel,
                    base.hushLabel,
                    base.weakerLabel,
                    base.strongerLabel
                ].forEach {
                    $0?.alpha = isHidden ? 0 : 1
                }
                
                base.addButton.alpha = !isHidden ? 0 : 1
            }
        }
    }
    
    func semicirclePath(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let centerPoint = CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height)
        path.addArc(withCenter: centerPoint,
                    radius: rect.width,
                    startAngle: 3 * CGFloat.pi / 2,
                    endAngle: 2 * CGFloat.pi,
                    clockwise: true)
        path.addLine(to: centerPoint)
        path.close()
        return path
    }

}
