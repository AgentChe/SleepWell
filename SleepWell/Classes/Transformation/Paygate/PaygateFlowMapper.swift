//
//  PaygateFlowMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 08.07.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

final class PaygateFlowMapper {
    static func map(response: Any) -> PaygateFlow? {
        guard
            let json = response as? [String: Any],
            let data = json["_data"] as? [String: Any],
            let flow = data["flow"] as? Int
        else {
            return nil
        }
        
        switch flow {
        case 1:
            return .paygateUponRequest
        case 2:
            return .blockOnboarding
        default:
            return nil
        }
    }
}
