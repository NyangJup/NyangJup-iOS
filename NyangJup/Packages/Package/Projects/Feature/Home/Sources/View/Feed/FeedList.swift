//
//  FeedList.swift
//  NJPackage
//
//  Created by 정지훈 on 7/16/26.
//

import SwiftUI

import DomainMediaInterface
import SharedDesign

struct FeedList: View {
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Constant.columnSpacing),
        GridItem(.flexible(), spacing: Constant.columnSpacing),
        GridItem(.flexible(), spacing: Constant.columnSpacing)
    ]

    let items: [FeedItem]
    let isInitialLoading: Bool
    let availableWidth: CGFloat
    let onTap: (Media) -> Void
    let onLoadNextPage: () -> Void

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: Constant.rowSpacing) {
                if isInitialLoading {
                    ForEach(0..<Constant.initialSkeletonCount, id: \.self) { _ in
                        Rectangle()
                            .frame(
                                width: cellSize.width,
                                height: cellSize.height
                            )
                            .clipShape(.rect(cornerRadius: Constant.cornerRadius))
                            .skeleton()
                    }
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { (index, item) in
                        Group {
                            switch item {
                            case let .media(media):
                                FeedCell(
                                    media: media,
                                    targetSize: cellSize,
                                    onTap: onTap
                                )
                            case .uploading:
                                UploadingFeedCell(targetSize: cellSize)
                            }
                        }
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
}

private extension FeedList {
    enum Constant {
        static let columnSpacing: CGFloat = 8
        static let rowSpacing: CGFloat = 16
        static let aspectRatio: CGFloat = 3 / 4
        static let prefetchItemCount: Int = 6
        static let initialSkeletonCount: Int = 9
        static let cornerRadius: CGFloat = 16
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
