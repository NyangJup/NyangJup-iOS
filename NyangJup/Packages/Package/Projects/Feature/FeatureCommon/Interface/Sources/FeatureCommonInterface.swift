//
//  FeatureCommonInterface.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

public protocol FeatureDelegate { }

public protocol FeatureConfiguration: Sendable { }

public protocol Factorable {
    var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView { get }
}

@MainActor
public protocol Coordinator<Route>: AnyObject {
    associatedtype Route: Hashable

    func push(to route: Route)
    func pop()
}

@MainActor
public protocol NZViewModel {
    associatedtype State
    associatedtype Action

    var state: State { get }
    
    func send(_ action: Action)
}
