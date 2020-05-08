//
//  PaygateService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

final class PaygateService {
    func paygete(from screen: String? = nil) -> Single<Paygate?> {
        let request = GetPaygateRequest(userToken: SessionService.userToken,
                                        locale: UIDevice.deviceLanguageCode,
                                        version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                                        screen: screen)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { PaygateMapper.parse(response: $0) }
            .flatMap { paygateInfo -> Single<Paygate?> in
                guard let info = paygateInfo else {
                    return .just(nil)
                }
                
                return PurchaseService().productPrice(productId: info.productId)
                    .map { price -> Paygate? in
                        return PaygateMapper.create(info: info.info, productPrice: price)
                    }
            }
    }
}
