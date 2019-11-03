//
//  PaymentService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import SwiftyStoreKit

class PurchaseService {
    static func register() {
        SwiftyStoreKit.completeTransactions { purchases in
            for purchase in purchases {
                let state = purchase.transaction.transactionState
                if state == .purchased || state == .restored {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
        }
    }
    
    func paymentValidate(receipt: String) -> Single<Session?> {
        let userToken = SessionService.userToken
        
        let request = PurchaseValidateRequest(receipt: receipt,
                                              userToken: userToken,
                                              version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { Session.parseFromDictionary(any: $0) }
            .do(onSuccess: { session in
                SessionService.store(userToken: session?.userToken)
            })
    }
    
    func paymentValidate() -> Single<Session?> {
        return receipt
            .flatMap { [weak self] receiptBase64 -> Single<Session?> in
                guard let `self` = self, let receipt = receiptBase64 else {
                    return .just(nil)
                }
                
                return self.paymentValidate(receipt: receipt)
            }
    }
    
    func buySubscription(productId: String) -> Single<Void> {
        return Single<Void>.create { single in
            SwiftyStoreKit.purchaseProduct(productId, quantity: 1, atomically: true) { result in
                switch result {
                case .success(_):
                    single(.success(Void()))
                case .error(_):
                    single(.error(PurchaseError.failedPurchaseProduct))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func restoreSubscription(productId: String) -> Single<Void> {
        return Single<Void>.create { single in
            SwiftyStoreKit.restorePurchases(atomically: true) { result in
                if result.restoredPurchases.isEmpty {
                    single(.error(PurchaseError.nonProductsForRestore))
                } else if result.restoredPurchases.contains(where: { $0.productId == productId }) {
                    single(.success(Void()))
                } else {
                    single(.error(PurchaseError.failedRestorePurchases))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func productPrice(productId: String) -> Single<String?> {
        return Single<String?>.create { single in
            SwiftyStoreKit.retrieveProductsInfo([productId]) { products in
                var price: String? = nil
                
                if let product = products.retrievedProducts.first {
                    price = product.localizedPrice
                }
                
                single(.success(price))
            }
            
            return Disposables.create()
        }
    }
    
    var receipt: Single<String?> {
        return Single<String?>.create { single in
            let receipt = SwiftyStoreKit.localReceiptData?.base64EncodedString()
            
            single(.success(receipt))
            
            return Disposables.create()
        }
    }
}

