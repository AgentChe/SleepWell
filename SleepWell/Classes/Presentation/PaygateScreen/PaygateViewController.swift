//
//  PaygateViewController.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import UIKit
import RxSwift

final class PaygateViewController: UIViewController {
    
}

extension PaygateViewController: BindsToViewModel {
    typealias ViewModel = PaygateViewModel
    
    static func make() -> PaygateViewController {
        let storyboard = UIStoryboard(name: "PaygateScreen", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "PaygateViewController") as! PaygateViewController
    }
    
    func bind(to viewModel: PaygateViewModelInterface, with input: ()) -> () {
        
    }
}
