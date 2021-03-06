//
//  SoundGroupCell.swift
//  SleepWell
//
//  Created by Vitaliy Zagorodnov on 04/01/2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

class SoundGroupCell: UITableViewCell {
    
    @IBOutlet private var groupView: SoundGroupView!
    
    func setup(model: NoiseCategory, isActiveSubscription: Bool, closure: @escaping ((SoundCellElement) -> Void)) {
        groupView.setup(model: model, isActiveSubscription: isActiveSubscription)
        groupView.selectedItem = closure
    }

}
