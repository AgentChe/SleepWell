//
//  MainViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol MainViewModelInterface {
    func sendPersonalData() -> Signal<Bool>
    func showPlayerScreen(
        detail: RecordingDetail,
        hideTabbarClosure: @escaping (Bool) -> Void
    )
}

final class MainViewModel: BindableViewModel, MainViewModelInterface {

    typealias Interface = MainViewModelInterface
    
    lazy var router: MainRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let personalDataService: PersonalDataService
    }
    
    func sendPersonalData() -> Signal<Bool> {
        return dependencies.personalDataService
            .sendPersonalData()
            .map { true }
            .asSignal(onErrorSignalWith: .never())
    }
    
    func showPlayerScreen(
        detail: RecordingDetail,
        hideTabbarClosure: @escaping (Bool) -> Void
    ) {
        router.showPlayerScreen(
            detail: detail,
            hideTabbarClosure: hideTabbarClosure
        )
    }
}
