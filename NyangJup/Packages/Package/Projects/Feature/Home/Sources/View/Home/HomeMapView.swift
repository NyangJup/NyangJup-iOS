//
//  HomeMapView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI
import SpriteKit

import CoreImageLoaderInterface
import DomainCatsInterface

struct HomeMapView: View {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.imageLoaderClient) private var imageLoaderClient

    @State private var scene: HomeMapScene?

    let cats: [Cat]
    let selectedCatID: String?
    let onCatTapped: (String, CGPoint) -> Void
    let onSelectionCleared: () -> Void

    var body: some View {
        GeometryReader { proxy in
            if let scene {
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .onChange(of: cats) {
                    scene.syncCats(cats)
                }
                .onChange(of: selectedCatID) {
                    if selectedCatID == nil {
                        scene.clearSelection()
                    }
                }
            } else {
                Color.clear
                    .onAppear {
                        makeScene(size: proxy.size)
                    }
                    .onChange(of: proxy.size) {
                        makeScene(size: proxy.size)
                    }
            }
        }
    }

    private func makeScene(size: CGSize) {
        guard scene == nil else { return }

        scene = HomeMapScene(
            size: size,
            cats: cats,
            imageLoaderClient: imageLoaderClient,
            displayScale: displayScale,
            onCatTapped: onCatTapped,
            onSelectionCleared: onSelectionCleared
        )
    }
}
