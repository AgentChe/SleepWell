//
//  PaygateService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class PaygateService {}

// MARK: Retrieve

extension PaygateService {
    func retrievePaygate(screen: String) -> Single<PaygateMapper.PaygateResponse?> {
        let request = GetPaygateRequest(userToken: SessionService.userToken,
                                        locale: UIDevice.deviceLanguageCode ?? "en",
                                        version: UIDevice.appVersion ?? "1",
                                        screen: screen,
                                        appKey: IDFAService.shared.getAppKey())
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { PaygateMapper.parse(response: $0, productsPrices: nil) }
    }
}

// MARK: Prepare prices

extension PaygateService {
    func prepareProductsPrices(for paygate: PaygateMapper.PaygateResponse) -> Single<PaygateMapper.PaygateResponse?> {
        guard !paygate.productsIds.isEmpty else {
            return .deferred { .just(paygate) }
        }
        
        return PurchaseService
            .productsPrices(ids: paygate.productsIds)
            .map { PaygateMapper.parse(response: paygate.json, productsPrices: $0.retrievedPrices) }
    }
}

// MARK: Ping

extension PaygateService {
    func ping() -> Single<Void> {
        RestAPITransport()
            .callServerApi(requestBody: PaygatePingRequest(randomKey: IDFAService.shared.getAppKey()))
            .map { _ in Void() }
    }
}
