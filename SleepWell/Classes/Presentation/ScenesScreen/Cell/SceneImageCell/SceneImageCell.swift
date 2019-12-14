//
//  SceneCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 29/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import Kingfisher

final class SceneImageCell: UICollectionViewCell {
    @IBOutlet private var sceneImage: UIImageView!

    func setup(model: SceneCellModelFields) {
        sceneImage.kf.indicatorType = .activity
        sceneImage.kf.setImage(with: model.url, options: [.transition(.fade(0.2))])
    }
}
