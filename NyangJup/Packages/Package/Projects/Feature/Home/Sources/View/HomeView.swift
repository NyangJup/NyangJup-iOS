import SwiftUI
import SpriteKit

public struct HomeView: View {
    let viewModel: HomeViewModel
    
    public init(
        viewModel: HomeViewModel
    ) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: HomeMapScene(size: proxy.size),
                options: [.allowsTransparency]
            )
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("냥줍 박스")
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
