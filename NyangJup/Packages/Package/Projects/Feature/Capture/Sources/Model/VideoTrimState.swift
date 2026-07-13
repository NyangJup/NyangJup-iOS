//
//  VideoTrimState.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import AVFoundation
import UIKit

public struct VideoTrimState {
    var duration: Double = 0
    var startTime: Double = 0
    var endTime: Double = 0
    var currentTime: Double = 0
    var thumbnails: [UIImage] = []

    var selectedDuration: Double {
        endTime - startTime
    }
}
