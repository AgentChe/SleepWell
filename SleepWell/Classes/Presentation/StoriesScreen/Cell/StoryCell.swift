//
//  StoryCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Kingfisher

class StoryCell: UITableViewCell {
    @IBOutlet private var backgroundImage: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var readerLabel: UILabel!
    @IBOutlet private var avatarImage: UIImageView!
    @IBOutlet private var lockedImage: UIImageView!
    
    func setup(model: StoryCellModel) {
        if let backgroundUrl = model.image {
            backgroundImage.kf.indicatorType = .activity
            backgroundImage.kf.setImage(with: backgroundUrl, options: [.transition(.fade(0.2))])
        }
        
        if let avatarUrl = model.avatar {
            avatarImage.kf.indicatorType = .activity
            avatarImage.kf.setImage(with: avatarUrl, options: [.transition(.fade(0.2))])
            
        }
        
        titleLabel.text = model.name
        lockedImage.isHidden = model.paid
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .short

        if let time = formatter.string(from: TimeInterval(model.time)) {
            readerLabel.text = "\(model.reader) · \(time)"
        } else {
            readerLabel.text = model.reader
        }
    }
}
