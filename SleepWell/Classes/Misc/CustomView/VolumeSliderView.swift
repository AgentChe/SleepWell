//
//  VolumeSliderView.swift
//  SleepWell
//
//  Created by Alexander Mironov on 05/11/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class VolumeSliderView: UIView {
    
    struct Input {
        let text: String
        let initialValue: Float
    }
    
    func configure(input: Input) {
        
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        cornerRadius = 18
        clipsToBounds = true
        
        let initialVolumeValue = frame.width * CGFloat(input.initialValue)
        volumeView.frame = .init(
            x: 0,
            y: 0,
            width: initialVolumeValue,
            height: frame.height
        )
        
        textLabel.text = input.text
        textLabel.frame = .init(
            x: 16,
            y: 14,
            width: textLabel.intrinsicContentSize.width,
            height: textLabel.intrinsicContentSize.height
        )
        
        let currentVolumeValue = gesture.rx.event
            .filter { $0.state == .ended }
            .map { [volumeView] _ in
                volumeView.frame.width
            }
            .startWith(initialVolumeValue)
            .asSignal(onErrorSignalWith: .empty())
        
        gesture.rx.event
            .asSignal(onErrorSignalWith: .empty())
            .filter { $0.state == .changed }
            .map { [weak self] pan in
                pan.translation(in: self).x
            }
            .withLatestFrom(currentVolumeValue, resultSelector: +)
            .map { [frame] value in
                max(CGFloat(0), min(value, frame.width))
            }
            .emit(to: Binder(self) { view, volume in
                view.volumeView.frame = .init(
                    x: 0,
                    y: 0,
                    width: volume,
                    height: view.frame.height
                )
            })
            .disposed(by: disposeBag)
    }
    
    private lazy var textLabel = UILabel().setup {
        addSubview($0)
        
        $0.font = UIFont(name: "Poppins-Semibold", size: 15)
        $0.textColor = #colorLiteral(red: 0.3098039216, green: 0.3098039216, blue: 0.3098039216, alpha: 1)
    }
    
    private lazy var volumeView = UIView().setup {
        addSubview($0)
        
        $0.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)
    }
    
    private lazy var gesture = UIPanGestureRecognizer().setup {
        addGestureRecognizer($0)
    }
    
    private let disposeBag = DisposeBag()
}
