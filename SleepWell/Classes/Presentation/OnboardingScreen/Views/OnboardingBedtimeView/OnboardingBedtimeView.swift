//
//  OnboardingBedtimeView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 30/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension String: PickerViewItem {}

class OnboardingBedtimeView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var hourPickerView: PickerView!
    @IBOutlet weak var minutePickerView: PickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    let nextUpWithTimeAndPushToken = PublishRelay<(time: String, pushToken: String)>()
    let nextUpWithout = PublishRelay<Void>()
    
    private lazy var hoursSource: [String] = {
        var array: [String] = []
        
        for i in 0...23 {
            if i < 10 {
                array.append("0\(i)")
            } else {
                array.append("\(i)")
            }
        }
        
        return array
    }()
    
    private lazy var minutesSource: [String] = {
        var array: [String] = []
        
        for i in 0...59 {
            if i < 10 {
                array.append("0\(i)")
            } else {
                array.append("\(i)")
            }
        }
        
        return array
    }()
    
    private lazy var hours = hoursSource
    private lazy var minutes = minutesSource
    
    private var selectedHour: String?
    private var selectedMinute: String?
    
    private let disposeBag = DisposeBag()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("OnboardingBedtimeView", owner: self)
        frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        hourPickerView.didSelectItem = { [weak self] item in
            guard let hour = item as? String else {
                return
            }
            
            self?.selectedHour = hour
        }
        
        minutePickerView.didSelectItem = { [weak self] item in
            guard let minute = item as? String else {
                return
            }
            
            self?.selectedMinute = minute
        }
        
        hourPickerView.bind(items: hours, map: { "\($0)" })
        minutePickerView.bind(items: minutes, map: { "\($0)" })
        
        skipButton.rx.tap
            .take(1)
            .bind(to: nextUpWithout)
            .disposed(by: disposeBag)
        
        nextButton.rx.tap
            .take(1)
            .subscribe(onNext: { [weak self] in
                guard let hour = self?.selectedHour, let minute = self?.selectedMinute else {
                    return
                }
                
                let time = String(format: "%@:%@", hour, minute)
                
                PushMessagesService.shared.register { isRegisteredForRemoteNotifications, token in
                    if isRegisteredForRemoteNotifications {
                        self?.nextUpWithTimeAndPushToken.accept((time, token ?? ""))
                    } else {
                        self?.nextUpWithout.accept(Void())
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    func show() {
        isHidden = false
        alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 1
        })
    }
    
    func hide(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.alpha = 0
        }, completion: { [weak self] _ in
            self?.isHidden = true
            
            completion()
        })
    }
}
