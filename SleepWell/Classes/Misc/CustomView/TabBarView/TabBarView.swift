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

    private func initialize() {
        UINib(nibName: "TabBarView", bundle: nil).instantiate(withOwner: self, options: nil)
        containerView.frame = bounds
        addSubview(containerView)
    }
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
