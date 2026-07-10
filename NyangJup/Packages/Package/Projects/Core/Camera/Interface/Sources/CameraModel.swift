//
//  CameraModel.swift
//  NJPackage
//
//  Created by 정지훈 on 7/7/26.
//

import Foundation

public enum CameraPosition: Equatable, Sendable {
    case back
    case front
}

public enum CaptureMode: Equatable, Sendable {
    case photo
    case video
}

public struct CapturedMedia: Equatable, Sendable {
    public let mode: CaptureMode
    public let url: URL?
    public let data: Data?

    public init(
        url: URL,
        mode: CaptureMode
    ) {
        self.mode = mode
        self.url = url
        self.data = nil
    }
    
    public init(
        data: Data,
        mode: CaptureMode
    ) {
        self.mode = mode
        self.url = nil
        self.data = data
    }
}
