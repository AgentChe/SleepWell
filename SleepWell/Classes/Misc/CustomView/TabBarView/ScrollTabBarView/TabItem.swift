//
//  TabItem.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 01/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class TabItem: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        alpha = 0.7
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var select: Bool = false {
        didSet {
            let opacity = select ? 1 : 0.7
            self.alpha = CGFloat(opacity)
        }
    }
    
    var title: String? {
        didSet {
            self.setTitle(title?.uppercased(), for: .normal)
            self.titleLabel?.font = UIFont.init(name: "Montserrat-Regular", size: 13)
        }
    }

}
