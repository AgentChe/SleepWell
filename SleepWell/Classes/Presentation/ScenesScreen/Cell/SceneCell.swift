//
//  SceneCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Kingfisher

class SceneCell: UICollectionViewCell {
    @IBOutlet private var sceneImage: UIImageView!

    func setup(model: SceneCellModel) {
        if let sceneUrl = model.image {
            sceneImage.kf.indicatorType = .activity
            sceneImage.kf.setImage(with: sceneUrl, options: [.transition(.fade(0.2))])
        }
    }
}
