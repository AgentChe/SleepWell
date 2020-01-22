//
//  ScrollTabBarView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 25/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension ScrollTabBarView {
    enum PlayerAction {
        case play, pause
    }
}

class ScrollTabBarView: UIView {

    @IBOutlet private var containerView: UIView!

    var items: [TabItem] = [] {
        didSet {
            items.forEach {
                stackView.addArrangedSubview($0)
            }
        }
    }
    
    var didTapMiniPlayer: Signal<PlayerAction> {
        return playerAction.asSignal()
    }
  
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    override func draw(_ rect: CGRect) {
        drawDecoration(frame: rect)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return path.contains(point)
    }

    private func initialize() {
        UINib(nibName: "ScrollTabBarView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = UIScreen.main.bounds

        addSubview(containerView)
        
        containerView.addSubview(contentView)
        
        contentView.addSubview(stackView)
        contentView.addSubview(miniPlayer)
        contentView.addSubview(selectedIndicator)
        
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.isUserInteractionEnabled = true
        
        contentView.frame.size = CGSize(width: containerView.bounds.width * 2 + 60, height: bounds.height)
        contentView.frame.origin = CGPoint(x: 0, y: 0)
        
        stackView.frame.size = CGSize(width: UIScreen.main.bounds.width, height: bounds.height)
        stackView.frame.origin = CGPoint(x: 0, y: 20)
        
        let size = miniPlayer.systemLayoutSizeFitting(
            CGSize(
                width: UIView.layoutFittingCompressedSize.width,
                height: bounds.height
            ),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        self.miniPlayer.frame = CGRect(origin: CGPoint(x: stackView.bounds.width, y: stackView.frame.origin.y), size: size)

        selectedAnimation()
        setupAnimation()
        
        miniPlayer.didTapPlay
            .emit(onNext: { [weak self] action in
                switch action {
                case .play:
                    self?.playerAction.accept(.play)
                case .pause:
                    self?.playerAction.accept(.pause)
                case .show:
                    self?.didTapPlayer()
                }
            })
            .disposed(by: disposeBag)
        
        
        rx.methodInvoked(#selector(UIView.layoutSubviews))
            .asSignal(onErrorSignalWith: .empty())
            .take(1)
            .emit(to: Binder(self) { view, _ in
//                let center = UIScreen.main.bounds.width - (UIScreen.main.bounds.width / 3) / 2
                
                let c = UIScreen.main.bounds.width / 4
                let cx3 = c * 3
                let center = cx3 - c / 2
                
                view.selectedIndicator.frame = CGRect(
                    origin: CGPoint(x: center, y: view.frame.height - 30),
                    size: CGSize(width: 5, height: 5)
                )
            })
            .disposed(by: disposeBag)
    }
    
    func showMiniPlayer(name: String) {
        guard miniPlayerIsHidden else { return }

        miniPlayerIsHidden = false
        miniPlayer.name = name
        addGestureRecognizer(panGesture)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.stackView.frame.size.width -= self.indentMiniPlayer
            self.miniPlayer.frame.origin.x -= self.indentMiniPlayer
            self.selectedIndicator.center.x -= self.stackView.frame.width
            self.stackView.frame.origin.x -= self.stackView.frame.width
            self.miniPlayer.center.x = self.containerView.convert(self.containerView.center, to: self.contentView).x
            self.miniPlayer.playerIsHidden = false
            self.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                self.miniPlayer.playerIsHidden = true
                self.stackView.frame.origin.x += self.stackView.frame.width
                self.miniPlayer.frame.origin.x = self.containerView.bounds.size.width - self.indentMiniPlayer
                self.selectedIndicator.center.x = (self.items.first(where: { $0.select })?.center.x ?? .zero) + 30
                self.layoutIfNeeded()
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.selectedIndicator.center.x -= 30
                }
            }
        }
    }
    
    func hideMiniPlayer() {
        guard !miniPlayerIsHidden else { return }
        
        miniPlayerIsHidden = true
        removeGestureRecognizer(panGesture)
        UIView.animate(withDuration: 0.2, delay: 0.3, options: [], animations: {
            self.contentView.frame.origin.x = 0
            self.stackView.frame.size.width += self.indentMiniPlayer
            self.miniPlayer.frame.origin.x += self.indentMiniPlayer
        }, completion: { _ in
            self.selectedIndicator.center.x = self.items.first(where: { $0.select })?.center.x ?? .zero
        })
    }
    
    private var miniPlayerIsHidden = true
    
    private var initialCenterIndicator: CGPoint = .zero
    private var path: UIBezierPath!
    private var initialCenter = CGPoint()
    
    private let miniPlayer = MiniPlayerView()
    private let stackView = UIStackView()
    private let panGesture = UIPanGestureRecognizer()
    private let contentView = UIView()
    private let selectedIndicator = UIImageView(image: UIImage(named: "ic_tab_select"))

    private let indentMiniPlayer: CGFloat = 50

    private let playerAction = PublishRelay<PlayerAction>()
    private let disposeBag = DisposeBag()
}

extension ScrollTabBarView {

    var selectIndex: Signal<Int> {
        return Observable.from(items).enumerated()
            .flatMap { (arg) -> Observable<Int> in
                let (indexItem, item) = arg
                return item.rx.tap
                    .asObservable()
                    .map { [weak self] _ -> Int in
                        self?.items.enumerated()
                            .forEach { arg in
                                let (index, item) = arg
                                item.select = index == indexItem
                            }
                        self?.selectedAnimation()
                        return indexItem
                    }
            }
            .startWith(2)
            .asSignal(onErrorJustReturn: 0)
    }
    // true - отображает кнопку паузы, false - плей
    var setPlayerState: Binder<Bool> {
        return Binder(miniPlayer) {
            $0.isPlaying = $1
        }
    }
}

private extension ScrollTabBarView {

    func didTapPlayer() {
        UIView.animate(withDuration: 0.3) {
            self.selectedIndicator.frame.origin.x -= self.indentMiniPlayer
            self.contentView.frame.origin.x -= self.stackView.frame.width
            self.miniPlayer.center.x = self.containerView.convert(self.containerView.center, to: self.contentView).x
            self.miniPlayer.playerIsHidden = false
            self.layoutIfNeeded()
        }
    }

    func selectedAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: { [weak self] in
            self?.selectedIndicator.center.x = self?.items.first(where: { $0.select })?.center.x ?? .zero
        }) { _ in  }
    }

    func setupAnimation() {
        panGesture.rx.event
            .bind { [weak self] gesture in
                guard gesture.view != nil, let self = self else { return }
                let translation = gesture.translation(in: self.contentView.superview)
                let velocity = gesture.velocity(in: self.containerView.superview)
                switch gesture.state {
                case .began:
                    self.initialCenter = self.contentView.center
                    self.initialCenterIndicator = self.selectedIndicator.center
                case .changed, .failed, .possible:
                    self.contentView.center.x = self.initialCenter.x + translation.x
                    self.selectedIndicator.center.x = self.items.first(where: { $0.select })?.center.x ?? .zero
                case .ended:
                    if velocity.x < 0 || translation.x < 0 {
                        if self.contentView.center.x < self.containerView.center.x {
                            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                                self.contentView.frame.origin.x -= translation.x
                            }) { _ in }
                        } else {
                            UIView.animate(withDuration: 0.3) {
                                self.selectedIndicator.center.x = -self.initialCenterIndicator.x + 80
                            }
                
                            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                                self.contentView.frame.origin.x = -self.initialCenter.x + 80
                                self.miniPlayer.center.x = self.containerView.convert(self.containerView.center, to: self.contentView).x
                                self.miniPlayer.playerIsHidden = false
                                self.layoutIfNeeded()
                            }) { _ in }
                        }
                    } else {
                        UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                            self.selectedIndicator.center.x += 50
                            self.contentView.frame.origin.x = 0
                            self.miniPlayer.frame.origin.x = self.stackView.frame.width
                            self.miniPlayer.playerIsHidden = true
                            self.layoutIfNeeded()
                        }) { _ in
                            UIView.animate(withDuration: 0.3) {
                                self.selectedIndicator.center.x -= 50
                            }
                        }
                }
                case .cancelled:
                    self.contentView.center = self.initialCenter
                @unknown default:
                    fatalError()
                }
            }
            .disposed(by: disposeBag)
    }

    func drawDecoration(frame: CGRect) {
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 0.00001 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 1.00000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 0.01553 * frame.height), controlPoint2: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 1.00000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.00000 * frame.width, y: frame.minY + 1.00000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.00000 * frame.width, y: frame.minY + 0.00001 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.00000 * frame.width, y: frame.minY + 1.00000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.00000 * frame.width, y: frame.minY + 0.00306 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.00677 * frame.width, y: frame.minY + 0.12620 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.00000 * frame.width, y: frame.minY + 0.04410 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.00238 * frame.width, y: frame.minY + 0.08653 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.40000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.02439 * frame.width, y: frame.minY + 0.28528 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.07439 * frame.width, y: frame.minY + 0.40000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.00003 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.40000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.00370 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.40000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.00370 * frame.height), controlPoint2: CGPoint(x: frame.minX + 0.13333 * frame.width, y: frame.minY + 0.40000 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 0.86667 * frame.width, y: frame.minY + 0.40000 * frame.height))
        bezierPath.addCurve(to: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 0.00000 * frame.height), controlPoint1: CGPoint(x: frame.minX + 0.94030 * frame.width, y: frame.minY + 0.40000 * frame.height), controlPoint2: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 0.22091 * frame.height))
        bezierPath.addLine(to: CGPoint(x: frame.minX + 1.00000 * frame.width, y: frame.minY + 0.00001 * frame.height))
        bezierPath.close()
        UIColor.gray.setFill()
        path = bezierPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = bezierPath.cgPath
        layer.mask = maskLayer
    }
}
