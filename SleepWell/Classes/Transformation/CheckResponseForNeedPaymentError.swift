//
//  CheckResponseForNeedPaymentError.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class CheckResponseForNeedPaymentError {
    static func isNeedPayment(jsonResponse: Any) throws -> Bool {
        guard let json = jsonResponse as? [String: Any] else {
            throw RxError.noElements
        }
        
        guard let needPayment = json["_need_payment"] as? Bool else {
            throw RxError.noElements
        }
        
        return needPayment
    }
}
