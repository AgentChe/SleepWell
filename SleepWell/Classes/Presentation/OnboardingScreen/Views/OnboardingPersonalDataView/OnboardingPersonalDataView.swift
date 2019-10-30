//
//  OnboardingPersonalDataView.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Int: PickerViewItem {}

class OnboardingPersonalDataView: UIView {
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var maleCheckView: CheckView!
    @IBOutlet weak var femaleCheckView: CheckView!
    @IBOutlet weak var otherCheckView: CheckView!
    @IBOutlet weak var pickerView: PickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    let nextWithPersonalData = PublishRelay<(Gender, Int)>()
    
    private lazy var source: [Int] = {
        var array: [Int] = []
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for i in 1960...currentYear {
            array.append(i)
        }
        
        return array
    }()
    
    private lazy var nextButtonColor = UIColor(red: 0.921, green: 0.894, blue: 0.909, alpha: 1)
    
    private var items: [Int] = []
    
    private var selectedYear: Int? {
        didSet {
            updateNextButton()
        }
    }
    
    private var selectedGender: Gender? {
        didSet {
            updateGenderViews()
            updateNextButton()
        }
    }
    
    private let disposeBag = DisposeBag()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        configure()
    }
    
    private func configure() {
        Bundle.main.loadNibNamed("OnboardingPersonalDataView", owner: self)
        frame = bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(containerView)
        
        items = source
        
        pickerView.didSelectItem = { [weak self] item in
            guard let year = item as? Int else {
                return
            }
            
            self?.selectedYear = year
        }
        
        pickerView.bind(items: items, map: { "\($0)" })
        
        maleCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .male }
        femaleCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .female }
        otherCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .other }
        
        updateGenderViews()
        updateNextButton()
        
        nextButton.rx.tap
            .throttle(RxTimeInterval.microseconds(500), scheduler: MainScheduler.asyncInstance)
            .flatMapLatest { [weak self] _ -> Observable<(Gender, Int)> in
                guard let gender = self?.selectedGender, let year = self?.selectedYear else {
                    return .never()
                }
                
                return .just((gender, year))
            }
            .bind(to: nextWithPersonalData)
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
    
    private func updateGenderViews() {
        maleCheckView.isCheck = selectedGender == Gender.male
        femaleCheckView.isCheck = selectedGender == Gender.female
        otherCheckView.isCheck = selectedGender == Gender.other
    }
    
    private func updateNextButton() {
        let isFilled = selectedYear != nil && selectedGender != nil
        nextButton.isEnabled = isFilled
        nextButton.backgroundColor = isFilled ? nextButtonColor : nextButtonColor.withAlphaComponent(0.3)
    }
}
