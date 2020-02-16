//
//  LoadingView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29.01.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

class LoadingView: UIView {

  override class var layerClass: AnyClass {
        return LoadingLayer.self
    }
    
    private var loadingLayer: LoadingLayer {
        return self.layer as! LoadingLayer
    }

    var percentage: CGFloat {
        get {
            return loadingLayer.percentage
        }
        set {
            var safeVal = max(0, newValue)
            safeVal = safeVal.truncatingRemainder(dividingBy: 1.0)
            loadingLayer.percentage = safeVal
            loadingLayer.setNeedsDisplay()
        }
    }
    
    override func tintColorDidChange() {
        loadingLayer.tintColor = self.tintColor
        loadingLayer.setNeedsDisplay()
    }
    
    private(set) var spinning: Bool = false
    
    func start() {
        let anim = CABasicAnimation(keyPath: #keyPath(LoadingLayer.percentage))
        anim.fromValue = 0
        anim.toValue =  1.0
        anim.byValue = 0.01
        anim.duration = 1
        anim.repeatCount = MAXFLOAT
        
        loadingLayer.add(anim, forKey: "spin")
        spinning = true
    }
    
    func stop() {
        loadingLayer.removeAnimation(forKey: "spin")
        spinning = false
    }
    
}
