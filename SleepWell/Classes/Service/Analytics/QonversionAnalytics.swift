//
//  QonversionAnalytics.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20.01.2021.
//  Copyright © 2021 Andrey Chernyshev. All rights reserved.
//

import Qonversion

final class QonversionAnalytics {
    static let shared = QonversionAnalytics()
    
    private init() {}
}

// MARK: API
extension QonversionAnalytics {
    func applicationdidFinishLaunchingWithOptions() {
        Qonversion.launch(withKey: "sUF9cD_o_JCKiNXIdwk-0NyB0rnuB840")
    }
}
