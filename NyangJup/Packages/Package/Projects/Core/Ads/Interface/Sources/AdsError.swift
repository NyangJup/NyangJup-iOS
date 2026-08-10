//
//  AdsError.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import Foundation

public enum AdsError: Error {
    case clientNotConfigured
    case adNotReady
    case noRootViewController
}
