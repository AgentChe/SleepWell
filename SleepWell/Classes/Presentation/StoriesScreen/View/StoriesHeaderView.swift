//
//  StoriesHeaderView.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class StoriesHeaderView: UIView {
    @IBOutlet private var titleView: HeaderTitleView!
    @IBOutlet private var randomButton: UIButton!
    @IBOutlet private var conteinerView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        initilize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func initilize() {
        UINib(nibName: "StoriesHeaderView", bundle: nil).instantiate(withOwner: self, options: nil)
        conteinerView.frame = bounds
        addSubview(conteinerView)
    }

    func setup(title: String, subtitle: String) {
        titleView.setup(title: title, subtitle: subtitle)
    }
}

extension StoriesHeaderView {
    var didTapRandom: Signal<Void> {
        randomButton.rx.tap.asSignal()
            .do(onNext: { AmplitudeAnalytics.shared.log(with: .playRandomStoryTap) })
    }
    
    var didTapMenu: Signal<Void> {
        titleView.menuButton.rx.tap.asSignal()
    }
}
