//
//  HomeMapView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import SwiftUI
import SpriteKit

import DomainCatsInterface

struct HomeMapView: View {
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
                .onChange(of: cats.map(\.id)) {
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
            onCatTapped: onCatTapped,
            onSelectionCleared: onSelectionCleared
        )
    }
}
