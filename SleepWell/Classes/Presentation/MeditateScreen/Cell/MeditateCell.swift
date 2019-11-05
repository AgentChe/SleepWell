//
//  MeditateCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class MeditateCell: UITableViewCell {

    @IBOutlet private var backgroundImage: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var avatarImage: UIImageView!
    @IBOutlet private var lockedImage: UIImageView!
    
    struct Model {
        let image: String
        let title: String
        let subtitle: String
        let avatar: String
        let isAvailable: Bool
    }
    
    func setup(model: Model) {
        backgroundImage.image = UIImage(named: model.image)
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        avatarImage.image = UIImage(named: model.avatar)
        lockedImage.isHidden = model.isAvailable
        isUserInteractionEnabled = model.isAvailable
    }
}
