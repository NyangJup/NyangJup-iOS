import SwiftUI


public protocol FeatureDelegate { }

public protocol FeatureConfiguration: Sendable { }

public protocol Factorable {
    var makeView: @MainActor @Sendable (FeatureConfiguration?, FeatureDelegate?) -> AnyView { get }
}

@MainActor
public protocol NZViewModel {
    associatedtype State
    associatedtype Action

    var state: State { get }
    
    func send(_ action: Action)
}
