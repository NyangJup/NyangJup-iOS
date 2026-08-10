//
//  RelayCatFactory+Live.swift
//  NJPackage
//
//  Created by 정지훈 on 7/22/26.
//

import SwiftUI

import CoreAdsInterface
import CoreImageLoaderInterface
import DomainMediaInterface
import FeatureRelayCatInterface

public extension RelayCatFactory {
    static func live(
        mediaClient: MediaClient,
        imageLoaderClient: ImageLoaderClient,
        adsClient: AdsClient
    ) -> Self {
        Self(
            makeView: { configuration, _ in
                guard let configuration = configuration as? RelayCatConfiguration else {
                    return AnyView(EmptyView())
                }

                return AnyView(
                    RelayCatView(
                        viewModel: RelayCatViewModel(
                            configuration: configuration,
                            mediaClient: mediaClient,
                            imageLoaderClient: imageLoaderClient,
                            adsClient: adsClient
                        )
                    )
                )
            }
        )
    }
}
