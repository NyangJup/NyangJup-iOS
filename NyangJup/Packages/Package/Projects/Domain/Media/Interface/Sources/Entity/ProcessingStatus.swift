//
//  ProcessingStatus.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

public enum ProcessingStatus: String, Sendable {
    case processing = "PROCESSING"
    case ready = "READY"
    case failed = "FAILED"
}
