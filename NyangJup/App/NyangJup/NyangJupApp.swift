import AVFAudio
import SwiftUI

import CoreAdsInterface
import CoreNetworkInterface
import DomainDeviceSecurityInterface
import DomainProfileInterface
import FeatureHome

@main
struct NyangJupApp: App {
    private let dependencies: AppDependencies

    @State private var showsSplash = true
    @State private var authenticationAttempt = 0
    @State private var isAuthenticated: Bool?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        dependencies = .live()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let isAuthenticated {
                    if isAuthenticated {
                        HomeRootView(
                            catsClient: dependencies.catsClient,
                            mediaClient: dependencies.mediaClient,
                            videoTrimClient: dependencies.videoTrimClient,
                            profileClient: dependencies.profileClient,
                            adsClient: dependencies.adsClient,
                            pixelRewardClient: dependencies.pixelRewardClient
                        )
                    } else {
                        Button("재시도") {
                            authenticationAttempt += 1
                        }
                    }
                }

                if showsSplash {
                    NyangJupSplashView(showSplash: $showsSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(\.captureFactory, dependencies.captureFactory)
            .environment(\.catRegistrationFactory, dependencies.catRegistrationFactory)
            .environment(\.imageLoaderClient, dependencies.imageLoaderClient)
            .environment(\.relayCatFactory, dependencies.relayCatFactory)
            .environment(\.nativeAdFactory, dependencies.nativeAdFactory)
            .task {
                await dependencies.adsClient.setup()
            }
            .task(id: authenticationAttempt) {
                guard isAuthenticated == nil ||
                      (isAuthenticated ?? false) == false
                else { return }
                
                do {
                    try await dependencies.deviceSecurityClient.authenticate()
                    _ = try await dependencies.profileClient.fetchProfile()
                    try Task.checkCancellation()
                    isAuthenticated = true
                } catch {
                    isAuthenticated = false
                }
            }
        }
    }
}
