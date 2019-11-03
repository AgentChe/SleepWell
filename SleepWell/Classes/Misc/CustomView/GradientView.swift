//
//  GradientView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class GradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
}
