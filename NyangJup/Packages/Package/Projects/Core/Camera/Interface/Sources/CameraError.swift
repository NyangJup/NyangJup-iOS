//
//  CameraError.swift
//  NJPackage
//
//  Created by 정지훈 on 7/7/26.
//

import Foundation

public enum CameraError: Error {
    case deviceUnavailable
    case inputUnavailable
    case notRecording
    case photoDataUnavailable
    case alreadyRecording
}
