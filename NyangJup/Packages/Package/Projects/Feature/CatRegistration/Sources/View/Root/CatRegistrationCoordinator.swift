import Foundation

import FeatureCommonInterface

enum CatRegistrationRoute: Hashable {
    case generateCat(Data)
}

@MainActor
@Observable
final class CatRegistrationCoordinator: Coordinator {
    typealias Route = CatRegistrationRoute

    var path: [CatRegistrationRoute] = []

    func push(to route: CatRegistrationRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }
}
