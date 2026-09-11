//
//  CatRegistrationExampleApp.swift
//  NyangJup
//
//  Created by 정지훈 on 9/11/26.
//

import SwiftUI

import CoreImageLoaderTesting
import DomainCatsTesting
import DomainMediaTesting
import FeatureCaptureTesting
import FeatureCatRegistration
import FeatureCatRegistrationInterface

@main
struct CatRegistrationExampleApp: App {
    private let factory = CatRegistrationFactory.live(
        catsClient: .test,
        mediaClient: .test
    )

    var body: some Scene {
        WindowGroup {
            factory.makeView(
                nil,
                CatRegistrationDelegate { _ in }
            )
            .environment(\.captureFactory, .test)
            .environment(\.imageLoaderClient, .test)
        }
    }
}
