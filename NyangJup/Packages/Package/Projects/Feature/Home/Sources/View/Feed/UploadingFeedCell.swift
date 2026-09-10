//
//  UploadingFeedCell.swift
//  NJPackage
//
//  Created by 정지훈 on 9/7/26.
//

import SwiftUI

struct UploadingFeedCell: View {
    let targetSize: CGSize

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.gray.opacity(0.2))

            ProgressView()
        }
        .frame(
            width: targetSize.width,
            height: targetSize.height
        )
        .clipShape(.rect(cornerRadius: Constant.cornerRadius))
    }
}

private extension UploadingFeedCell {
    enum Constant {
        static let cornerRadius: CGFloat = 16
    }
}
