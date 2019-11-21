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
        let programmaticallyValue: Signal<Float>
        
        init(
            text: String,
            initialValue: Float,
            programmaticallyValue: Signal<Float> = .empty()
        ) {
            self.text = text
            self.initialValue = initialValue
            self.programmaticallyValue = programmaticallyValue
        }
    }
    
    var volume: Signal<Float> {
        _volume.asSignal()
    }
    
    func configure(input: Input) {
        
        disposeBag = DisposeBag()
        
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        clipsToBounds = true
        cornerRadius = 18
        
        let width = rx.methodInvoked(#selector(UIView.layoutSubviews))
            .take(1)
            .asSignal(onErrorSignalWith: .empty())
            .map { [weak self] _ in
                self?.frame.width ?? 0.0
            }
        
        let initialVolumeValue = width.map { $0 * CGFloat(input.initialValue) }
        
        let programmaticallyValue = input.programmaticallyValue
            .withLatestFrom(width) { CGFloat($0) * $1 }
        
        initialVolumeValue
            .emit(to: Binder(self) { view, width in
                view.volumeView.frame = .init(
                    x: 0,
                    y: 0,
                    width: width,
                    height: view.frame.height
                )
                
                view.textLabel.text = input.text
                view.textLabel.frame = .init(
                    x: 16,
                    y: 14,
                    width: view.textLabel.intrinsicContentSize.width,
                    height: view.textLabel.intrinsicContentSize.height
                )
            })
            .disposed(by: disposeBag)
        
        let volumeWidth = gesture.rx.event
            .asSignal()
            .filter { $0.state == .ended }
            .map { [volumeView] _ in
                volumeView.frame.width
            }
        
        let currentVolumeValue = Signal
            .merge(
                volumeWidth,
                initialVolumeValue,
                programmaticallyValue
            )
        
        let volumeChangeEvent = gesture.rx.event
            .asSignal(onErrorSignalWith: .empty())
            .filter { $0.state == .changed }
            .map { [weak self] pan in
                pan.translation(in: self).x
            }
            .withLatestFrom(currentVolumeValue, resultSelector: +)
            .withLatestFrom(width) { (value: $0, width: $1) }
            .map { tuple in
                max(CGFloat(0), min(tuple.value, tuple.width))
            }
        
        let volume = Signal
            .merge(
                volumeChangeEvent,
                programmaticallyValue
            )
        
        volume
            .emit(to: Binder(self) { view, volume in
                view.volumeView.frame = .init(
                    x: 0,
                    y: 0,
                    width: volume,
                    height: view.frame.height
                )
            })
            .disposed(by: disposeBag)
        
        volume
            .withLatestFrom(width) { Float($0 / $1) }
            .emit(to: _volume)
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
    
    private let _volume = PublishRelay<Float>()
    private var disposeBag = DisposeBag()
}
