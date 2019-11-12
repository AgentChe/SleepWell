//
//  OnboardingViewModel.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import RxCocoa

protocol OnboardingViewModelInterface {
    func goToPaygate(paygateCompletion: @escaping (PaygateCompletionResult) -> ())
    func goToMainScreen(behave: MainScreenBehave)
    
    func buildPersonalData() -> Signal<PersonalData>
    func complete(with paygateResult: PaygateCompletionResult, behave: OnboardingViewModel.Behave) -> Signal<MainScreenBehave>
    
    var setAims: PublishRelay<[Aim]> { get }
    var setGender: PublishRelay<Gender> { get }
    var setBirthYear: PublishRelay<Int> { get }
    var setPushToken: PublishRelay<String?> { get }
    var setPushTime: PublishRelay<String?> { get }
}

final class OnboardingViewModel: BindableViewModel, OnboardingViewModelInterface {
    enum Behave {
        case simple
        case requirePersonalData
    }
    
    typealias Interface = OnboardingViewModelInterface
    
    lazy var router: OnboardingRouter = deferred()
    lazy var dependencies: Dependencies = deferred()
    
    struct Dependencies {
        let personalDataService: PersonalDataService
    }
    
    let setAims = PublishRelay<[Aim]>()
    let setGender = PublishRelay<Gender>()
    let setBirthYear = PublishRelay<Int>()
    let setPushToken = PublishRelay<String?>()
    let setPushTime = PublishRelay<String?>()
    
    private var personalData: PersonalData?
    
    func goToPaygate(paygateCompletion: @escaping (PaygateCompletionResult) -> ()) {
        router.goToPaygate(completion: paygateCompletion)
    }
    
    func goToMainScreen(behave: MainScreenBehave) {
        router.goToMainScreen(behave: behave)
    }
    
    func complete(with paygateResult: PaygateCompletionResult, behave: Behave) -> Signal<MainScreenBehave> {
        switch behave {
        case .simple:
            switch paygateResult {
            case .purchased, .restored:
                return dependencies.personalDataService
                    .sendPersonalData()
                    .map { .withActiveSubscription }
                    .asSignal(onErrorSignalWith: .never())
            case .closed:
                return .just(.withoutActiveSubscription)
            }
        case .requirePersonalData:
            switch paygateResult {
            case .purchased, .restored:
                return dependencies.personalDataService
                    .sendPersonalData()
                    .map { .withActiveSubscription }
                    .asSignal(onErrorSignalWith: .never())
            case .closed:
                guard let personalData = self.personalData else {
                    return .never()
                }
                
                return dependencies.personalDataService
                    .store(personalData: personalData)
                    .map { MainScreenBehave.withoutActiveSubscription }
                    .asSignal(onErrorSignalWith: .never())
            }
        }
    }
    
    func buildPersonalData() -> Signal<PersonalData> {
        return Observable
            .combineLatest(setAims.asObservable(),
                           setGender.asObservable(),
                           setBirthYear.asObservable(),
                           setPushToken.asObservable(),
                           setPushTime.asObservable())
            .map { aims, gender, birthYear, pushToken, pushTime -> PersonalData in
                return PersonalData(aims: aims,
                                    gender: gender,
                                    birthYear: birthYear,
                                    pushToken: pushToken,
                                    pushTime: pushTime,
                                    pushIsEnabled: pushToken != nil)
            }
            .asSignal(onErrorSignalWith: .never())
            .do(onNext: { [weak self] personalData in
                self?.personalData = personalData
            })
    }
}