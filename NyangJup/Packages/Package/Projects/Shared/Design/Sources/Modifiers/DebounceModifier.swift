//
//  DebounceModifier.swift
//  NJPackage
//
//  Created by 정지훈 on 7/23/26.
//

import SwiftUI

public extension View {
    func debounce<Value: Equatable & Sendable>(
        value: Value,
        for duration: Duration,
        perform action: @escaping @MainActor @Sendable (Value) -> Void
    ) -> some View {
        modifier(
            DebounceModifier(
                value: value,
                duration: duration,
                action: action
            )
        )
    }
}

private struct DebounceModifier<Value: Equatable & Sendable>: ViewModifier {
    @State private var latestEventId: UUID?

    let value: Value
    let duration: Duration
    let action: @MainActor @Sendable (Value) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                let eventId = UUID()
                latestEventId = eventId

                Task {
                    try? await Task.sleep(for: duration)

                    guard latestEventId == eventId else { return }
                    action(newValue)
                }
            }
    }
}
