//
//  HTTPStatusCode.swift
//  NJPackage
//
//  Created by 정지훈 on 7/1/26.
//

import Foundation

public enum HTTPStatusCode {
    public static let success = 200...299
    
    public static let badRequest = 400
    public static let unauthorized = 401
    public static let notFound = 404
    public static let requestTimeout = 408
    
    public static let clientError = 400...499
    public static let serverError = 500...599
}
