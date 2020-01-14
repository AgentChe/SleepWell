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
    
    @IBOutlet private var contentView: UIView!
    
    private var volumeValue: CGFloat {
        (contentView.bounds.height - 120) / 100
    }
    
    private var volumeFactor: CGFloat {
        (contentView.bounds.width - 76) / 100
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
        
        weakerLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        strongerLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        
        let sounds = noiseSounds
            .compactMap { $0 }
            .scan([Noise]()) { old, new in
                var result = old
                result.append(new)
                return result
            }
        
        let viewsTranslation = noiseSounds
            .delay(.milliseconds(550), scheduler: MainScheduler.instance)
            .compactMap(setupNoiseView)
            .scan([NoiseView]()) { old, new in
                var result = old
                result.append(new)
                return result
            }
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
            .share(scope: .whileConnected)
        
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
        
        self.contentView.addSubview(noiseView)
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
            let posY = floor(center.y)
            let posX = floor(center.x)
            let volume = abs(Float(ceil((1 - posY / 100 / self.volumeValue) * 10) / 10))
            let factor = abs(Float(ceil((1 - posX / 100 / self.volumeFactor) * 10) / 10))
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
}

private extension ViewportView {
    
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
}
