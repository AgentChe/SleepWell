//
//  TabBarItem.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TabBarItem: UIView {

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var buttonTab: UIButton!
    @IBOutlet private var selectedImage: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    var isSelected: Bool = false {
        didSet {
            let opacity = isSelected ? 1 : 0.7
            selectedImage.isHidden = !isSelected
            containerView.alpha = CGFloat(opacity)
        }
    }
    
    var title: String? {
        didSet {
            buttonTab.setTitle(title?.uppercased(), for: .normal)
        }
    }

    private func initialize() {
        UINib(nibName: "TabBarItem", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        addSubview(containerView)
        selectedImage.isHidden = true
    }
}

extension TabBarItem {
    var didSelect: Signal<Void> {
        return buttonTab.rx.tap.asSignal()
    }
}
