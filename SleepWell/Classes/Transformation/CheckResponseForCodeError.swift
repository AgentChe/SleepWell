//
//  CheckResponseForCodeError.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 31/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift

class CheckResponseForCodeError {
    static func isError(jsonResponse: Any) throws -> Bool {
        guard let json = jsonResponse as? [String: Any] else {
            throw RxError.noElements
        }
        
        guard let code = json["_code"] as? Int else {
            throw RxError.noElements
        }
        
        return code < 200 && code > 299
    }
}
