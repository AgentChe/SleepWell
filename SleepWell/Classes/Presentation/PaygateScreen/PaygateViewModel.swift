//
//  PaygateViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol PaygateViewModelInterface {
    
}

final class PaygateViewModel: BindableViewModel {
    typealias Interface = PaygateViewModelInterface
    
    lazy var router: PaygateRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {}
}

extension PaygateViewModel: PaygateViewModelInterface {
    
}
