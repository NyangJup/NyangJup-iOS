//
//  EnvironmentEntryTests.swift
//  NJPackage
//
//  Created by 정지훈 on 9/11/26.
//

import Foundation
import SwiftUI
import Testing
import UIKit

import CoreAdsInterface
import CoreImageLoaderInterface
import FeatureCaptureInterface
import FeatureCatRegistrationInterface
import FeatureRelayCatInterface

@MainActor
private final class FactoryCallRecorder {
    private(set) var callCount = 0

    func record() {
        callCount += 1
    }
}

@Test @MainActor
func captureFactoryEnvironmentCanBeOverridden() {
    let recorder = FactoryCallRecorder()
    var environment = EnvironmentValues()
    environment.captureFactory = CaptureFactory { _, _ in
        recorder.record()
        return AnyView(EmptyView())
    }

    _ = environment.captureFactory.makeView(nil, nil)

    #expect(recorder.callCount == 1)
}

@Test @MainActor
func catRegistrationFactoryEnvironmentCanBeOverridden() {
    let recorder = FactoryCallRecorder()
    var environment = EnvironmentValues()
    environment.catRegistrationFactory = CatRegistrationFactory { _, _ in
        recorder.record()
        return AnyView(EmptyView())
    }

    _ = environment.catRegistrationFactory.makeView(nil, nil)

    #expect(recorder.callCount == 1)
}

@Test @MainActor
func relayCatFactoryEnvironmentCanBeOverridden() {
    let recorder = FactoryCallRecorder()
    var environment = EnvironmentValues()
    environment.relayCatFactory = RelayCatFactory { _, _ in
        recorder.record()
        return AnyView(EmptyView())
    }

    _ = environment.relayCatFactory.makeView(nil, nil)

    #expect(recorder.callCount == 1)
}

@Test @MainActor
func nativeAdFactoryEnvironmentCanBeOverridden() {
    let recorder = FactoryCallRecorder()
    var environment = EnvironmentValues()
    environment.nativeAdFactory = NativeAdFactory { _ in
        recorder.record()
        return AnyView(EmptyView())
    }

    _ = environment.nativeAdFactory.makeView(
        NativeAdItem(object: NSObject())
    )

    #expect(recorder.callCount == 1)
}

@Test @MainActor
func imageLoaderClientEnvironmentCanBeOverridden() async throws {
    let expectedImage = UIImage()
    var environment = EnvironmentValues()
    environment.imageLoaderClient = ImageLoaderClient { _, _, _, _ in
        expectedImage
    }

    let loadedImage = try await environment.imageLoaderClient.loadImage(
        URL(string: "https://example.com/cat.png")!,
        CGSize(width: 20, height: 20),
        2,
        [.memory]
    )

    #expect(loadedImage === expectedImage)
}
