//
//  PaygateMapper.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 28/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

typealias Paygate = (productId: PaygateMapper.PaygateProductId, preBuyButtonInfo: String?, postBuyButtonInfo: String?, buyButtonText: String?)

class PaygateMapper {
    typealias PaygateResponse = (info: PaygateInfo, productId: PaygateProductId)
    typealias PaygateInfo = [String: Any]
    typealias PaygateProductId = String
    
    static func parse(response: Any) -> PaygateResponse? {
        guard let dict = response as? [String: Any], let data = dict["_data"] as? [String: Any], let productId = data["product_id"] as? String else {
            return nil
        }
        
        let info = [
            "pre_button": data["pre_button"] as? String as Any,
            "post_button": data["post_button"] as? String as Any,
            "button": data["button"] as? String as Any,
            "product_id": productId
        ] as [String : Any]
        
        return (info: info, productId: productId)
    }
    
    static func create(info: PaygateInfo, productPrice: String?) -> Paygate? {
        guard let productId = info["product_id"] as? String else {
            return nil
        }
                
        let preBuyButtonInfoOriginal = info["pre_button"] as? String ?? ""
        let preBuyButtonInfo = preBuyButtonInfoOriginal.replacingOccurrences(of: "@price", with: productPrice ?? "")
        
        let postBuyButtonInfoOriginal = info["post_button"] as? String ?? ""
        let postBuyButtonInfo = postBuyButtonInfoOriginal.replacingOccurrences(of: "@price", with: productPrice ?? "")
        
        let buyButtonTextOriginal = info["button"] as? String ?? ""
        let buyButtonText = buyButtonTextOriginal.replacingOccurrences(of: "@price", with: productPrice ?? "")

        return (productId, preBuyButtonInfo, postBuyButtonInfo, buyButtonText)
    }
}

