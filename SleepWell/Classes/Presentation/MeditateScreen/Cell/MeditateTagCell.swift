//
//  MeditateTagCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class MeditateTagCell: UICollectionViewCell {
    @IBOutlet private var titleLabel: UILabel!
    
    func setup(model: TagCellModel) {
        titleLabel.text = model.name
        contentView.backgroundColor = model.isSelected ? .white : .clear
        titleLabel.textColor = model.isSelected ? .black : .white
    }
}
