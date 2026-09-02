//
//  PresignedUploadSource.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import Foundation

public enum PresignedUploadSource: Sendable {
    case data(Data)
    case file(URL)
}
