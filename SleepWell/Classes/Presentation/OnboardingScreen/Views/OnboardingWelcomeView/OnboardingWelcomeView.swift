//
//  OnboardingWelcomeView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum SwipeDirection {
    case left, right
}

class OnboardingWelcomeView: UIView {
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "welcome")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var label: UILabel = {
        let attr = TextAttributes()
            .font(Font.Poppins.semibold(size: 22))
            .lineHeight(32)
            .letterSpacing(-0.3)
            .textAlignment(.center)
            .textColor(.white)
        
        let label = UILabel()
        label.attributedText = "swipe_left_or_right_to_change_scene".localized.attributed(with: attr)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nextUpWithSwipeDirection = PublishRelay<SwipeDirection>()
    
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
        addSubviews()
        addActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
        addSubviews()
        addActions()
    }
    
    private func configure() {
        isHidden = true
        backgroundColor = .clear
    }
    
    private func addSubviews() {
        addSubview(containerView)
        addSubview(imageView)
        addSubview(label)
        
        containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32).isActive = true
        
        imageView.widthAnchor.constraint(equalToConstant: 273).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 51).isActive = true
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -48).isActive = true
    }
    
    private func addActions() {
        let leftSwipeGesture = UISwipeGestureRecognizer()
        leftSwipeGesture.direction = .left
        
        let rightSwipeGesture = UISwipeGestureRecognizer()
        rightSwipeGesture.direction = .right
        
        containerView.addGestureRecognizer(leftSwipeGesture)
        containerView.addGestureRecognizer(rightSwipeGesture)
        
        Observable.merge(leftSwipeGesture.rx.event.map { _ -> SwipeDirection in .left },
                         rightSwipeGesture.rx.event.map { _ -> SwipeDirection in .right })
            .bind(to: nextUpWithSwipeDirection)
            .disposed(by: disposeBag)
    }
    
    func show() {
        AmplitudeAnalytics.shared.log(with: .slideScr)
        
        isHidden = false
        alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 1
        })
    }
    
    func hide(swipeDirection: SwipeDirection, completion: @escaping () -> ()) {
        var x: CGFloat = 0
        if swipeDirection == .left {
            x = -1000
        } else if swipeDirection == .right {
            x = 1000
        }
        
        let transform = self.transform.translatedBy(x: x, y: 0)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.transform = transform
        }, completion: { [weak self] _ in
            self?.isHidden = true
            
            completion()
        })
    }
}
