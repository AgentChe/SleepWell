//
//  OnboardingAimTableCell.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class OnboardingAimTableCell: UITableViewCell {
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkedImageView: UIImageView!
    
    private lazy var selectedBackgroundColor = UIColor(red: 0.792, green: 0.760, blue: 0.756, alpha: 1)
    private lazy var unSelectedBackgroundColor = UIColor.clear
    
    private lazy var selectedTitleColor = UIColor(red: 0.541, green: 0.498, blue: 0.525, alpha: 1)
    private lazy var unSelectedTitleColor = UIColor(red: 0.921, green: 0.898, blue: 0.917, alpha: 1)
    
    private lazy var selectedImg = UIImage(named: "checked")
    private lazy var unSelectedImg = UIImage(named: "unchecked")
    
    var selectItem: ((OnboardingAimItem) -> ())?
    
    private var item: OnboardingAimItem!
    
    func bind(item: OnboardingAimItem) {
        self.item = item
        
        titleLabel.text = item.title
        titleLabel.textColor = item.isSelected ? selectedTitleColor : unSelectedTitleColor
        checkedImageView.image = item.isSelected ? selectedImg : unSelectedImg
        selectedView.backgroundColor = item.isSelected ? selectedBackgroundColor : unSelectedBackgroundColor
    }
    
    @IBAction func didSelectItem(_ sender: Any) {
        selectItem?(item)
    }
}
