//
//  SoundCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class SoundCell: UICollectionViewCell {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    
    func setup(image: String, title: String) {
        imageView.image = UIImage(named: image)
        nameLabel.text = title
    }
}
