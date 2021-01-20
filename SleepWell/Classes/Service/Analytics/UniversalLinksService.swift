//
//  UniversalLinksService.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20.09.2020.
//  Copyright © 2020 Andrey Chernyshev. All rights reserved.
//

import UIKit

final class UniversalLinksService {
    static let shared = UniversalLinksService()
    
    private init() {}
}

// MARK: API

extension UniversalLinksService {
    func register(didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if
            let userActivityDictionary = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [UIApplication.LaunchOptionsKey: Any],
            let userActivityId = userActivityDictionary[.userActivityType] as? String {
            let userActivity = NSUserActivity(activityType: userActivityId)
            
            register(with: userActivity)
        } else {
            parseWithFacebook { parsedWithFacebook in
                if let _parsedWithFacebook = parsedWithFacebook {
                    UniversalLinksService.shared.setAttributions(_parsedWithFacebook)
                }
            }
        }
    }
    
    func register(with userActivity: NSUserActivity) {
        parse(from: userActivity) { parsed in
            if let _parsed = parsed {
                UniversalLinksService.shared.setAttributions(_parsed)
                
                return
            }
            
            UniversalLinksService.shared.parseWithBranch { parsedWithBranch in
                if let _parsedWithBranch = parsedWithBranch {
                    UniversalLinksService.shared.setAttributions(_parsedWithBranch)
                    
                    return
                }
                
                UniversalLinksService.shared.parseWithFacebook() { parsedWithFacebook in
                    if let _parsedWithFacebook = parsedWithFacebook {
                        UniversalLinksService.shared.setAttributions(_parsedWithFacebook)
                        
                        return
                    }
                }
            }
        }
    }
    
    func register(with url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {
        parseWithBranch { parsedWithBranch in
            if let _parsedWithBranch = parsedWithBranch {
                UniversalLinksService.shared.setAttributions(_parsedWithBranch)
                
                return
            }
            
            UniversalLinksService.shared.parseWithFacebook(url: url) { parsedWithFacebook in
                if let _parsedWithFacebook = parsedWithFacebook {
                    UniversalLinksService.shared.setAttributions(_parsedWithFacebook)
                    
                    return
                }
            }
        }
    }
}

// MARK: Private

private extension UniversalLinksService {
    func parse(from userActivity: NSUserActivity, handler: ((UniversalLinkAttributions?) -> Void)) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else {
            handler(nil)
            
            return
        }
        
        let attributions = create(from: url)
        
        handler(attributions)
    }
    
    func parseWithBranch(handler: ((UniversalLinkAttributions?) -> Void)) {
        guard let dict = BranchService.shared.getLastAttributions() else {
            handler(nil)
            
            return
        }
        
        let attributions = UniversalLinkAttributions(channel: dict["channel"] as? String,
                                                     campaign: dict["campaign"] as? String,
                                                     adgroup: dict["adgroup"] as? String,
                                                     feature: dict["feature"] as? String)
        
        let result = isEmpty(attributions: attributions) ? nil : attributions
        
        handler(result)
    }
    
    
    func parseWithFacebook(url: URL? = nil, handler: @escaping ((UniversalLinkAttributions?) -> Void)) {
        FacebookAnalytics.shared.fetchDeferredLink { result in
            guard let link = (result ?? url) else {
                handler(nil)
                
                return
            }
            
            let attributions = UniversalLinksService.shared.create(from: link)
            
            handler(attributions)
        }
    }
    
    func create(from url: URL) -> UniversalLinkAttributions? {
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return nil
        }
        
        let attributions = UniversalLinkAttributions(channel: queryItems.first(where: { $0.name == "channel" })?.value,
                                                     campaign: queryItems.first(where: { $0.name == "campaign" })?.value,
                                                     adgroup: queryItems.first(where: { $0.name == "adgroup" })?.value,
                                                     feature: queryItems.first(where: { $0.name == "feature" })?.value)
        
        return isEmpty(attributions: attributions) ? nil : attributions
    }
    
    func setAttributions(_ attributions: UniversalLinkAttributions) {
        let request = SetUniversalLinkAttributionsRequest(appKey: IDFAService.shared.getAppKey(),
                                                          channel: attributions.channel,
                                                          campaign: attributions.campaign,
                                                          adgroup: attributions.adgroup,
                                                          feature: attributions.feature)
        
        _ = RestAPITransport()
            .callServerApi(requestBody: request)
            .subscribe()
    }
    
    func isEmpty(attributions: UniversalLinkAttributions) -> Bool {
        attributions.channel == nil
            && attributions.campaign == nil
            && attributions.adgroup == nil
            && attributions.feature == nil
    }
}

