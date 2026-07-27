//
//  CapturedPhotoView.swift
//  NJPackage
//
//  Created by 정지훈 on 7/27/26.
//

import SwiftUI

struct CapturedPhotoView: View {
    let data: Data

    var body: some View {
        if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipped()
                .background(.black)
        }
    }
}
