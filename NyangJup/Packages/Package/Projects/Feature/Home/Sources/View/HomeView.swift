import SwiftUI
import SpriteKit

public struct HomeView: View {
    @State private var viewModel: HomeViewModel

    public init(
        viewModel: HomeViewModel
    ) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            mapView
        }
        .overlay(alignment: .topLeading) {
            titleView
        }
        .overlay(alignment: .bottomTrailing) {
            bottomButton
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.send(.view(.onAppear))
        }
    }
}

// MARK: - UI

private extension HomeView {
    var mapView: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: HomeMapScene(
                    size: proxy.size,
                    cats: viewModel.state.cats
                ),
                options: [.allowsTransparency]
            )
            .id(viewModel.state.cats.map(\.id).joined())
        }
    }

    var titleView: some View {
        Text(Constant.title)
            .font(.largeTitle)
            .padding(.leading, Constant.titleLeadingPadding)
            .padding(.top, Constant.titleTopPadding)
    }

    var bottomButton: some View {
        Button {

        } label: {
            bottomButtonImage
        }
        .frame(width: Constant.bottomButtonSize, height: Constant.bottomButtonSize)
        .glassEffect(.clear.interactive(), in: .circle)
        .padding(.trailing, Constant.bottomButtonTrailingPadding)
        .padding(.bottom, Constant.bottomButtonBottomPadding)
    }

    var bottomButtonImage: some View {
        Image(systemName: Constant.bottomButtonImage)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.black)
            .frame(width: Constant.bottomButtonImageSize, height: Constant.bottomButtonImageSize)
    }
}

// MARK: - Constants

private extension HomeView {
    private enum Constant {
        static let title: String = "냥줍"
        static let bottomButtonImage: String = "plus"

        static let titleLeadingPadding: CGFloat = 32
        static let titleTopPadding: CGFloat = 60

        static let bottomButtonImageSize: CGFloat = 24
        static let bottomButtonSize: CGFloat = 60
        static let bottomButtonTrailingPadding: CGFloat = 20
        static let bottomButtonBottomPadding: CGFloat = 48
    }
}
