//
//  Mime.swift
//  SleepWell
//
//  Created by Andrey Chernyshev on 20/12/2019.
//  Copyright © 2019 Andrey Chernyshev. All rights reserved.
//

enum Mime: Int {
    case jpg = 1
    case bmp1 = 2
    case bmp2 = 3
    case gif = 4
    case imgOther = 5

    case qt_mov = 6
    case mp4 = 7
    case gp3 = 8
    case avi = 9
    case videoOther = 10
}

extension Mime {
    var isImage: Bool {
        return self == .jpg
            || self == .bmp1
            || self == .bmp2
            || self == .gif
            || self == .imgOther
    }
    
    var isVideo: Bool {
        return self == .qt_mov
            || self == .mp4
            || self == .gp3
            || self == .avi
            || self == .videoOther
    }
}
