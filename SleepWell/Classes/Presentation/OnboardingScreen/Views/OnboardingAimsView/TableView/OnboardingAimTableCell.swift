//
//  OnboardingAimTableCell.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class OnboardingAimTableCell: UITableViewCell {
    @IBOutlet weak var checkView: CheckView!
    
    var selectItem: ((OnboardingAimItem) -> ())?
    
    func bind(item: OnboardingAimItem) {
        checkView.title = item.title
        
        checkView.changedCheck = { [weak self] _ in
            self?.selectItem?(item)
        }
    }
}
