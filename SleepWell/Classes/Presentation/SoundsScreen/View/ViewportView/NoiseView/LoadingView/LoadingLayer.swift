//
//  LoadingLayer.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29.01.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

class LoadingLayer: CALayer {

    var tintColor: UIColor? = UIColor.black
    
    @objc dynamic var percentage: CGFloat = 0
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        
        if let other = layer as? LoadingLayer {
            self.tintColor = other.tintColor
            self.percentage = other.percentage
        }
        else {
            fatalError()
        }
        
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(in ctx: CGContext) {
        let center = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
        
        let radius = bounds.width
        let fillColor = tintColor ?? UIColor.black
        
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setFillColor(fillColor.cgColor)
        
        ctx.beginPath()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: -.pi / 2.0)
        
        ctx.move(to: .zero)
        ctx.addArc(center: .zero,
                   radius: radius,
                   startAngle: 0,
                   endAngle: 2 * CGFloat.pi * percentage,
                   clockwise: false)
        
        ctx.closePath()
        
        ctx.drawPath(using: .fill)
    }
    
    
    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(LoadingLayer.percentage) {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
    
    override func action(forKey event: String) -> CAAction? {
        
        if event == #keyPath(LoadingLayer.percentage) {
            let anim = CABasicAnimation(keyPath: #keyPath(LoadingLayer.percentage))
            anim.byValue = 0.01
            anim.timingFunction = CAMediaTimingFunction(name: .linear)
            anim.fromValue = presentation()?.percentage ?? 0
            return anim
        }
        return super.action(forKey: event)
    }
}
