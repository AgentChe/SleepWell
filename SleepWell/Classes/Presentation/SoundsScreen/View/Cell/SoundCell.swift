//
//  SoundCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Kingfisher

final class SoundCell: UICollectionViewCell {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var lockedView: UIView!
    
    func setup(image: URL, title: String, paid: Bool) {
        imageView.kf.setImage(with: image, options: [.transition(.fade(0.2))])
        nameLabel.text = title
        lockedView.isHidden = paid
    }
}
