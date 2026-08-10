import SwiftUI

import DomainCatsInterface
import DomainMediaInterface
import FeatureCaptureInterface

struct CatRegistrationRootView: View {
    @Environment(\.captureFactory) private var captureFactory

    @State private var coordinator: CatRegistrationCoordinator

    private let catsClient: CatsClient
    private let mediaClient: MediaClient
    private let onComplete: @MainActor (Cat) -> Void
    private let onClose: @MainActor () -> Void

    init(
        catsClient: CatsClient,
        mediaClient: MediaClient,
        onComplete: @escaping @MainActor (Cat) -> Void,
        onClose: @escaping @MainActor () -> Void
    ) {
        self._coordinator = State(
            initialValue: CatRegistrationCoordinator()
        )
        self.catsClient = catsClient
        self.mediaClient = mediaClient
        self.onComplete = onComplete
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            captureFactory.makeView(
                CaptureConfiguration(
                    usage: .catRegistration,
                    showsModePicker: false
                ),
                CaptureDelegate(send: { action in
                    switch action {
                    case .close:
                        onClose()
                    case .complete:
                        break
                    case let .register(media):
                        guard let data = media.data else { return }
                        coordinator.push(to: .generateCat(data))
                    }
                })
            )
            .navigationDestination(for: CatRegistrationRoute.self) { route in
                switch route {
                case let .generateCat(data):
                    GenerateCatView(
                        viewModel: GenerateCatViewModel(
                            photoData: data,
                            catsClient: catsClient,
                            mediaClient: mediaClient,
                            onComplete: { cat in
                                onComplete(cat)
                            },
                            onError: {
                                coordinator.pop()
                            }
                        )
                    )
                }
            }
        }
    }
}
