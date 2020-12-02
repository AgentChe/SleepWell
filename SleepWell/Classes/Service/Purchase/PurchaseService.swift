//
//  PaymentService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import SwiftyStoreKit

final class PurchaseService {
    func isNeedPayment(by meditationId: Int) -> Single<Bool> {
        let userToken = SessionService.session?.userToken
        
        let request = CheckActiveSubscriptionRequest(userToken: userToken, meditationId: meditationId)
        
        return SDKStorage.shared
            .restApiTransport
            .callServerApi(requestBody: request)
            .map { try CheckResponseForNeedPaymentError.isNeedPayment(jsonResponse: $0) }
    }
}
