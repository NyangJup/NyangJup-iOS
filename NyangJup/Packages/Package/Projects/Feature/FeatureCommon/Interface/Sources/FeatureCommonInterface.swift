import SwiftUI

public protocol Factorable {
    var makeView: () -> AnyView { get }
    var makeViewModel: () -> any NZViewModel { get }
}

public protocol NZViewModel {
    associatedtype State
    associatedtype Action

    var state: State { get }
    
    func send(_ action: Action)
}
