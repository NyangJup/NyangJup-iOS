import Testing
@testable import FeatureHome
import DomainCatsTesting
import DomainProfileTesting

@MainActor
@Test
func plusButtonPresentsCapture() {
    let viewModel = HomeViewModel(
        catsClient: .test,
        profileClient: .test
    )

    #expect(viewModel.state.isCapturePresented == false)
    viewModel.send(.view(.plusButtonTapped))
    #expect(viewModel.state.isCapturePresented == true)
    viewModel.send(.view(.captureDismissed))
    #expect(viewModel.state.isCapturePresented == false)
}
