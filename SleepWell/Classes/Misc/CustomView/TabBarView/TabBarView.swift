//
//  TabBarView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TabBarView: UIView {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var stackView: UIStackView!
    var items: [TabBarItem] = [] {
        didSet {
            items.forEach {
                stackView.addArrangedSubview($0)
                items.first?.isSelected = true
            }
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
    
    override func draw(_ rect: CGRect) {
        drawDecoration(frame: rect)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return path.contains(point)
    }

    private func initialize() {
        UINib(nibName: "TabBarView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        addSubview(containerView)
    }
    
    private func drawDecoration(frame: CGRect) {
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
    
    private var path: UIBezierPath!
}

extension TabBarView {
    var selectIndex: Signal<Int> {
        return Observable.from(items).enumerated()
            .flatMap { (arg) -> Observable<Int> in
                let (indexItem, item) = arg
                return item.didSelect
                    .asObservable()
                    .map { [weak self] _ -> Int in
                        self?.items.enumerated()
                            .forEach { arg in
                                let (index, item) = arg
                                item.isSelected = index == indexItem
                            }
                        return indexItem
                    }
            }
            .startWith(0)
            .asSignal(onErrorJustReturn: 0)
    }
}
