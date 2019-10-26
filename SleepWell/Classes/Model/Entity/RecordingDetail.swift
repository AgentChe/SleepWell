//
//  RecordingDetail.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 26/10/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

protocol RecordingDetail: Model {
    var recording: Recording { get }
    var readingSound: Sound { get }
    var ambientSound: Sound? { get }
}
