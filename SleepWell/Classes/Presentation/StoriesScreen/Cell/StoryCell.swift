//
//  StoryCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit

class StoryCell: UITableViewCell {
    @IBOutlet private var backgroundImage: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var readerLabel: UILabel!
    @IBOutlet private var avatarImage: UIImageView!
    @IBOutlet private var lockedImage: UIImageView!
    
    struct Model {
        let image: String
        let name: String
        let avatar: String
        let reader: String
        let time: Int
        let isAvailble: Bool
    }

    func setup(model: Model) {
        backgroundImage.image = UIImage(named: model.image)
        titleLabel.text = model.name
        avatarImage.image = UIImage(named: model.avatar)
        lockedImage.isHidden = model.isAvailble
        isUserInteractionEnabled = model.isAvailble
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
