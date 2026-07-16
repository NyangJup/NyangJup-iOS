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
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let items: [Media]

    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items, id: \.self.id) { item in
                    FeedCell(media: item)
                }
            }
        }
    }
}

struct FeedCell: View {
    let media: Media

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.orange)
            .aspectRatio(3/4, contentMode: .fit)
    }
}
