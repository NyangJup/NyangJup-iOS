//
//  FeedList.swift
//  NJPackage
//
//  Created by 정지훈 on 7/16/26.
//

import SwiftUI

import DomainMediaInterface

struct FeedList: View {
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Constant.columnSpacing),
        GridItem(.flexible(), spacing: Constant.columnSpacing),
        GridItem(.flexible(), spacing: Constant.columnSpacing)
    ]

    let items: [Media]
    let availableWidth: CGFloat
    let onTap: (Media) -> Void
    let onLoadNextPage: () -> Void

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: Constant.rowSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { (index, item) in
                    FeedCell(
                        media: item,
                        targetSize: cellSize,
                        onTap: onTap
                    )
                    .onAppear {
                        if index == loadNextPageIndex {
                            onLoadNextPage()
                        }
                    }
                }
            }
        }
    }
}

private extension FeedList {
    enum Constant {
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 16
        static let aspectRatio: CGFloat = 3 / 4
        static let prefetchItemCount: Int = 6
    }

    var cellSize: CGSize {
        let totalSpacing = Constant.columnSpacing * CGFloat(columns.count - 1)
        let width = (availableWidth - totalSpacing) / CGFloat(columns.count)

        return CGSize(
            width: width,
            height: width / Constant.aspectRatio
        )
    }
    
    var loadNextPageIndex: Int {
        max(items.count - Constant.prefetchItemCount, 0)
    }
}
