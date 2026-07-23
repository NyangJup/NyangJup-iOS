import Testing
import SwiftUI
import UIKit

@testable import SharedDesign

@MainActor
private final class DebounceTestModel: ObservableObject {
    @Published var value = 0
    private(set) var receivedValues: [Int] = []

    func receive(_ value: Int) {
        receivedValues.append(value)
    }
}

private struct DebounceTestView: View {
    @ObservedObject var model: DebounceTestModel

    var body: some View {
        Color.clear
            .debounce(
                value: model.value,
                for: .milliseconds(30),
                perform: model.receive
            )
    }
}

@MainActor
@Test
func debounceDeliversOnlyLatestValue() async throws {
    let model = DebounceTestModel()
    let viewController = UIHostingController(
        rootView: DebounceTestView(model: model)
    )
    let window = UIWindow(
        frame: CGRect(x: 0, y: 0, width: 390, height: 844)
    )
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    viewController.view.layoutIfNeeded()

    model.value = 1
    try await Task.sleep(for: .milliseconds(10))
    model.value = 2
    try await Task.sleep(for: .milliseconds(60))

    #expect(model.receivedValues == [2])
    _ = window
}
