//
//  SettingsViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 05/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SettingsViewController: UIViewController {
    private lazy var textAttributes: TextAttributes = {
        return TextAttributes()
            .textColor(.black)
            .font(Font.OpenSans.regular(size: 17))
            .letterSpacing(-0.5)
            .lineHeight(22)
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.backgroundColor = UIColor(red: 184 / 255, green: 182 / 255, blue: 191 / 255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var termsOfServiceView: SettingsItemView = {
        let view = SettingsItemView()
        view.label.attributedText = "terms_of_service".localized.attributed(with: textAttributes)
        return view
    }()
    
    private lazy var privacyPolicyView: SettingsItemView = {
        let view = SettingsItemView()
        view.label.attributedText = "privacy_police".localized.attributed(with: textAttributes)
        return view
    }()
    
    private lazy var contactUsView: SettingsItemWithImageView = {
        let view = SettingsItemWithImageView()
        view.imageView.image = UIImage(named: "message")
        view.label.attributedText = "contact_us".localized.attributed(with: textAttributes)
        return view
    }()
    
    private lazy var leaveReviewView: SettingsItemWithImageView = {
        let view = SettingsItemWithImageView()
        view.imageView.image = UIImage(named: "star")
        view.label.attributedText = "leave_a_review".localized.attributed(with: textAttributes)
        return view
    }()
    
    private lazy var titleView: UILabel = {
        let attr = TextAttributes()
            .textColor(.black)
            .font(Font.Poppins.bold(size: 34))
            .lineHeight(41)
        
        let label = UILabel()
        label.attributedText = "settings".localized.attributed(with: attr)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var sliderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let sliderView = UIView()
        sliderView.backgroundColor = UIColor(red: 142 / 255, green: 142 / 255, blue: 147 / 255, alpha: 1)
        sliderView.layer.cornerRadius = 2
        sliderView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(sliderView)
        sliderView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        sliderView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12.5).isActive = true
        sliderView.widthAnchor.constraint(equalToConstant: 33).isActive = true
        sliderView.heightAnchor.constraint(equalToConstant: 4).isActive = true
        
        return view
    }()
    
    private var containerViewBottomConstraint: NSLayoutConstraint!
    
    private let disposeBag = DisposeBag()
    
    private var isShowed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AmplitudeAnalytics.shared.log(with: .settingsScr)
        
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animateShow()
    }
    
    private func configure() {
        addSubviews()
        addActions()
    }
    
    
    private func addSubviews() {
        view.addSubview(containerView)
        containerView.addSubview(termsOfServiceView)
        containerView.addSubview(privacyPolicyView)
        containerView.addSubview(contactUsView)
        containerView.addSubview(leaveReviewView)
        containerView.addSubview(titleView)
        containerView.addSubview(sliderView)
        
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 400)
        containerViewBottomConstraint.isActive = true

        termsOfServiceView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        termsOfServiceView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -17).isActive = true
        termsOfServiceView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28).isActive = true
        termsOfServiceView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        privacyPolicyView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        privacyPolicyView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -17).isActive = true
        privacyPolicyView.bottomAnchor.constraint(equalTo: termsOfServiceView.topAnchor, constant: -20).isActive = true
        privacyPolicyView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        contactUsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        contactUsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -17).isActive = true
        contactUsView.bottomAnchor.constraint(equalTo: privacyPolicyView.topAnchor, constant: -20).isActive = true
        contactUsView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        leaveReviewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        leaveReviewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -17).isActive = true
        leaveReviewView.bottomAnchor.constraint(equalTo: contactUsView.topAnchor, constant: -20).isActive = true
        leaveReviewView.heightAnchor.constraint(equalToConstant: 28).isActive = true

        titleView.bottomAnchor.constraint(equalTo: leaveReviewView.topAnchor, constant: -38).isActive = true
        titleView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        titleView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -17).isActive = true

        sliderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        sliderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        sliderView.bottomAnchor.constraint(equalTo: titleView.topAnchor, constant: -15).isActive = true
        sliderView.heightAnchor.constraint(equalToConstant: 22.5).isActive = true
        sliderView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    }
    
    private func addActions() {
        
        let backgroundTap = UITapGestureRecognizer()
        backgroundTap.delegate = self
        view.addGestureRecognizer(backgroundTap)
        
        let panGesture = UIPanGestureRecognizer()
        containerView.addGestureRecognizer(panGesture)
        
        Signal
            .merge(
                panGesture.rx.event
                    .asSignal()
                    .filter { $0.state == .changed }
                    .map { [view] pan in
                        pan.translation(in: view).y
                    }
                    .filter { $0 > 0 }
                    .map { _ in () },
                backgroundTap.rx.event.asSignal()
                    .map { _ in () }
            )
            .take(1)
            .emit(to: Binder(self) { base, _ in
                base.animateHide()
            })
            .disposed(by: disposeBag)
        
        Observable
            .merge(leaveReviewView.button.rx.tap.map { GlobalDefinitions.appStoreUrl },
                   contactUsView.button.rx.tap.map { GlobalDefinitions.contactUsUrl },
                   privacyPolicyView.button.rx.tap.map { GlobalDefinitions.privacyPolicyUrl },
                   termsOfServiceView.button.rx.tap.map { GlobalDefinitions.termsOfServiceUrl })
            .subscribe(onNext: { path in
                guard let url = URL(string: path), UIApplication.shared.canOpenURL(url) else {
                    return
                }
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func animateShow() {
        guard !isShowed else { return }
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0)
        
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            self?.containerViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
    }
    
    private func animateHide() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.backgroundColor = UIColor.black.withAlphaComponent(0)
            self?.containerViewBottomConstraint.constant = 400
            self?.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.dismiss(animated: false)
        })
    }
}

extension SettingsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        touch.view == view
    }
}
