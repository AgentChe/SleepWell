//
//  PaygateMainView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 12/06/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class PaygateMainView: UIView {
    lazy var backgroundImageView = makeBackgroundImageView()
    lazy var restoreButton = makeRestoreButton()
    lazy var greetingLabel = makeGreetingLabel()
    lazy var iconView = makeIconView()
    lazy var textLabel = makeTextLabel()
    lazy var leftOptionView = makeOptionView()
    lazy var rightOptionView = makeOptionView()
    lazy var continueButton = makeContinueButton()
    lazy var lockImageView = makeLockIconView()
    lazy var termsOfferLabel = makeTermsOfferLabel()
    lazy var purchasePreloaderView = makePreloaderView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(design: PaygateViewModel.PaygateOpenedFrom) {
        updateBackground(at: design)
    }
    
    func setup(paygate: PaygateMain) {
        greetingLabel.attributedText = paygate.greeting
        textLabel.text = paygate.text
        continueButton.setTitle(paygate.button, for: .normal)
        termsOfferLabel.text = paygate.subButton
        restoreButton.setTitle(paygate.restore, for: .normal)
        
        let options = paygate.options?.prefix(2) ?? []
        
        if let leftOption = options.first {
            leftOptionView.isHidden = false
            leftOptionView.isSelected = true
            leftOptionView.setup(option: leftOption)
        } else {
            leftOptionView.isHidden = true
        }
        
        if options.count > 1, let rightOption = options.last {
            rightOptionView.isHidden = false
            rightOptionView.setup(option: rightOption)
        } else {
            rightOptionView.isHidden = true
        }
    }
}

// MARK: Private

private extension PaygateMainView {
    func updateBackground(at openedFrom: PaygateViewModel.PaygateOpenedFrom) {
        var name = ScreenSize.isIphoneXFamily ? "paygate_main_background_X" : "paygate_main_background"
        
        switch openedFrom {
        case .onboarding, .promotionInApp:
            name += "_1"
        case .scenes:
            name += "_2"
        case .meditations:
            name += "_3"
        case .stories:
            name += "_4"
        case .sounds:
            name += "_5"
        }
        
        backgroundImageView.image = UIImage(named: name)
    }
}

// MARK: Make constraints

private extension PaygateMainView {
    func makeConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: topAnchor, constant: ScreenSize.isIphoneXFamily ? 41.scale : 31.scale),
            restoreButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32.scale),
            restoreButton.heightAnchor.constraint(equalToConstant: 30.scale)
        ])
        
        NSLayoutConstraint.activate([
            greetingLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scale),
            greetingLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -16.scale),
            greetingLabel.topAnchor.constraint(equalTo: topAnchor, constant: ScreenSize.isIphoneXFamily ? 159.scale : 114.scale)
        ])
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64.scale),
            iconView.heightAnchor.constraint(equalToConstant: 64.scale),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.scale),
            iconView.centerYAnchor.constraint(equalTo: greetingLabel.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scale),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.scale),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: ScreenSize.isIphoneXFamily ? 244.scale : 199.scale)
        ])
        
        NSLayoutConstraint.activate([
            leftOptionView.widthAnchor.constraint(equalTo: rightOptionView.widthAnchor),
            leftOptionView.heightAnchor.constraint(equalToConstant: 185.scale),
            leftOptionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scale),
            leftOptionView.trailingAnchor.constraint(equalTo: rightOptionView.leadingAnchor, constant: -13.scale),
            leftOptionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: ScreenSize.isIphoneXFamily ? -295.scale : -195.scale)
        ])
        
        NSLayoutConstraint.activate([
            rightOptionView.heightAnchor.constraint(equalToConstant: 185.scale),
            rightOptionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.scale),
            rightOptionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: ScreenSize.isIphoneXFamily ? -295.scale : -195.scale)
        ])
        
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56.scale),
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scale),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.scale),
            continueButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: ScreenSize.isIphoneXFamily ? -146.scale : -76.scale)
        ])
        
        NSLayoutConstraint.activate([
            lockImageView.widthAnchor.constraint(equalToConstant: 12.scale),
            lockImageView.heightAnchor.constraint(equalToConstant: 16.scale),
            lockImageView.trailingAnchor.constraint(equalTo: termsOfferLabel.leadingAnchor, constant: -10.scale),
            lockImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: ScreenSize.isIphoneXFamily ? -108.scale : -38.scale)
        ])
        
        NSLayoutConstraint.activate([
            termsOfferLabel.centerYAnchor.constraint(equalTo: lockImageView.centerYAnchor),
            termsOfferLabel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 10.scale)
        ])
        
        NSLayoutConstraint.activate([
            purchasePreloaderView.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
            purchasePreloaderView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

// MARK: Lazy initialization

private extension PaygateMainView {
    func makeRestoreButton() -> UIButton {
        let view = UIButton()
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        view.titleLabel?.font = Font.Poppins.regular(size: 18.scale)
        view.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        addSubview(view)
        return view
    }
    
    func makeBackgroundImageView() -> UIImageView {
        let view = UIImageView()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeGreetingLabel() -> UILabel {
        let view = UILabel()
        view.alpha = 0
        view.numberOfLines = 1
        view.textColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeIconView() -> UIImageView {
        let view = UIImageView()
        view.alpha = 0
        view.image = UIImage(named: "paygate_icon")
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeTextLabel() -> UILabel {
        let view = UILabel()
        view.alpha = 0
        view.font = Font.Poppins.regular(size: 17.scale)
        view.textColor = .white
        view.numberOfLines = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeOptionView() -> PaygateOptionView {
        let view = PaygateOptionView()
        view.alpha = 0
        view.layer.cornerRadius = 8.scale
        view.layer.borderWidth = 2.scale
        view.layer.borderColor = UIColor.white.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeContinueButton() -> UIButton {
        let view = UIButton()
        view.isHidden = true
        view.backgroundColor = .white
        view.layer.cornerRadius = 28.scale
        view.titleLabel?.font = Font.Poppins.bold(size: 17.scale)
        view.setTitleColor(.black, for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeLockIconView() -> UIImageView {
        let view = UIImageView()
        view.alpha = 0
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "paygate_main_lock")
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makeTermsOfferLabel() -> UILabel {
        let view = UILabel()
        view.alpha = 0
        view.font = Font.OpenSans.semibold(size: 13.scale)
        view.textColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
    
    func makePreloaderView() -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        view.style = .whiteLarge
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        return view
    }
}
