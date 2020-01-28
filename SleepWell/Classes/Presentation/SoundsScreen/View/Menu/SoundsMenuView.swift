//
//  SoundsMenu.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SoundsMenuView: UIView {
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var sleepItemView: UIView!
    @IBOutlet private var clearAllItemView: UIView!
    
    private let sleepTapGesture = UITapGestureRecognizer()
    private let clearAllTapGesture = UITapGestureRecognizer()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("SoundsMenuView", owner: self)
        containerView.frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        sleepItemView.addGestureRecognizer(sleepTapGesture)
        clearAllItemView.addGestureRecognizer(clearAllTapGesture)
    }
}

extension SoundsMenuView {
    var didTapSleep: Signal<Void> {
        return sleepTapGesture.rx.event
            .map { _ in Void() }
            .asSignal(onErrorSignalWith: .never())
    }
    
    var didTapClearAll: Signal<Void> {
        return clearAllTapGesture.rx.event
            .map { _ in Void() }
            .asSignal(onErrorSignalWith: .never())
    }
}
