//
//  RestAPITransport.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 25/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

import RxSwift
import Alamofire
import UIKit

class RestAPITransport {
    func callServerApi(requestBody: APIRequestBody) -> Observable<Any> {
        return Observable.create { observer in
            let manager = Alamofire.SessionManager.default
            manager.session.configuration.timeoutIntervalForRequest = 30
            
            let encodedUrl = requestBody.url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            let request = manager.request(encodedUrl,
                                          method: requestBody.method,
                                          parameters: requestBody.parameters,
                                          encoding: requestBody.encoding,
                                          headers: requestBody.headers)
                .validate(statusCode: [200, 201])
                .responseJSON(completionHandler: { response in
                    switch response.result {
                    case .success(let json):
                        observer.onNext(json)
                        observer.onCompleted()
                    case .failure(_):
                        observer.onError((response.response?.statusCode ?? -1) == 401 ? ApiError.unauthorized : ApiError.serverNotAvailable)
                    }
                })
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}
