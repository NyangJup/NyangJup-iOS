//
//  APIErrorResponse.swift
//  NJPackage
//
//  Created by 정지훈 on 8/28/26.
//

import Foundation

public struct APIErrorResponse: Decodable, Equatable, Sendable {
    public let status: Int
    public let message: String
    public let code: String
 
    public init(
        status: Int,
        message: String,
        code: String
    ) {
        self.status = status
        self.message = message
        self.code = code
    }
    
}
