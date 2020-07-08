//
//  PaygateScreenAssembly.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

final class PaygateAssembly: ScreenAssembly {
    typealias VC = PaygateViewController
    
    func assembleDependencies() -> VC.ViewModel.Dependencies {
        return VC.ViewModel.Dependencies(
            paygateManager: PaygateManager.shared,
            purchaseService: PurchaseService(),
            personalDataService: PersonalDataService()
        )
    }
}
