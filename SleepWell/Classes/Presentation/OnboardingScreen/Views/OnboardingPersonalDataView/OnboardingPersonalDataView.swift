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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var maleCheckView: CheckView!
    @IBOutlet weak var femaleCheckView: CheckView!
    @IBOutlet weak var otherCheckView: CheckView!
    @IBOutlet weak var pickerView: PickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    let nextUpWithPersonalData = PublishRelay<(Gender, Int)>()
    
    private lazy var source: [Int] = {
        var array: [Int] = []
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for i in 1960...currentYear {
            array.append(i)
        }
        
        return array
    }()
    
    private var years: [Int] = []
    
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
        
        years = source
        
        pickerView.didSelectItem = { [weak self] item in
            guard let year = item as? Int else {
                return
            }
            
            self?.selectedYear = year
        }
        
        pickerView.bind(items: years, map: { "\($0)" })
        
        maleCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .male }
        femaleCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .female }
        otherCheckView.changedCheck = { [weak self] _ in self?.selectedGender = .other }
        
        updateGenderViews()
        updateNextButton()
        setupUI()
        
        nextButton.rx.tap
            .throttle(RxTimeInterval.microseconds(500), scheduler: MainScheduler.asyncInstance)
            .flatMapLatest { [weak self] _ -> Observable<(Gender, Int)> in
                guard let gender = self?.selectedGender, let year = self?.selectedYear else {
                    return .never()
                }
                
                return .just((gender, year))
            }
            .bind(to: nextUpWithPersonalData)
            .disposed(by: disposeBag)
    }
    
    func show() {
        SDKStorage.shared
            .amplitudeManager
            .logEvent(name: "Gender and age scr", parameters: [:])
        
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
        nextButton.isUserInteractionEnabled = isFilled
        nextButton.alpha = isFilled ? 1 : 0.1
    }
    
    private func setupUI() {
        let titleAttr = TextAttributes()
            .font(Font.Poppins.bold(size: 34))
            .lineHeight(41)
            .textAlignment(.center)
            .textColor(.white)
        
        titleLabel.attributedText = "make_it_your_own".localized.attributed(with: titleAttr)
        
        let subtitleAttr = TextAttributes()
            .font(Font.Poppins.medium(size: 17))
            .lineHeight(22)
            .letterSpacing(-0.5)
            .textAlignment(.center)
            .textColor(UIColor.white)
        
        subtitleLabel.attributedText = "get_recommended_content_based_on_your_gender_and_age".localized.attributed(with: subtitleAttr)
    }
}
