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
    static func register() {
        SwiftyStoreKit.completeTransactions { purchases in
            AppStateProxy.ApplicationProxy.completeTransactions.accept(Void())
            
            for purchase in purchases {
                let state = purchase.transaction.transactionState
                if state == .purchased || state == .restored {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
        }
        
        SwiftyStoreKit.shouldAddStorePaymentHandler = { _, _ in
            AppStateProxy.NavigateProxy.openPaygateAtPromotionInApp.accept(Void())
            
            return true
        }
    }
    
    func isNeedPayment(by meditationId: Int) -> Single<Bool> {
        let userToken = SessionService.userToken
        
        let request = CheckActiveSubscriptionRequest(userToken: userToken, meditationId: meditationId)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { try CheckResponseForNeedPaymentError.isNeedPayment(jsonResponse: $0) }
    }
}

// MARK: Purchase

extension PurchaseService {
    func buySubscription(productId: String) -> Single<Void> {
        Single<Void>.create { single in
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
        Single<Void>.create { single in
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
}

// MARK: Validate

extension PurchaseService {
    func paymentValidate(receipt: String) -> Single<Session?> {
        let userToken = SessionService.userToken
        
        let request = PurchaseValidateRequest(receipt: receipt,
                                              userToken: userToken,
                                              version: Bundle.main.infoDictionary?["CFBundleVersion"] as? String)
        
        return RestAPITransport()
            .callServerApi(requestBody: request)
            .map { Session.parseFromDictionary(any: $0) }
            .do(onSuccess: { session in
                SessionService.store(session: session)
                
                if session?.userToken != nil {
                    AppStateProxy.UserTokenProxy.didUpdatedUserToken.accept(Void())
                }
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
}

// MARK: Price

extension PurchaseService {
    static func productsPrices(ids: [String]) -> Single<RetrievedProductsPrices> {
        Single<RetrievedProductsPrices>.create { event in
            SwiftyStoreKit.retrieveProductsInfo(Set(ids)) { products in
                let retrieved: [ProductPrice] = products
                    .retrievedProducts
                    .compactMap { ProductPrice(product: $0) }
                
                let invalidated = products
                    .invalidProductIDs
                
                let result = RetrievedProductsPrices(retrievedPrices: retrieved, invalidatedIds: Array(invalidated))
                
                event(.success(result))
            }
            
            return Disposables.create()
        }
    }
}

// MARK: Receipt

extension PurchaseService {
    var receipt: Single<String?> {
        Single<String?>.create { single in
            let receipt = SwiftyStoreKit.localReceiptData?.base64EncodedString()
            
            single(.success(receipt))
            
            return Disposables.create()
        }
    }
}
