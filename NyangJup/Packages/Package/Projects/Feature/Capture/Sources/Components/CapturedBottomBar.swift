//
//  CapturedBottomBar.swift
//  NJPackage
//
//  Created by 정지훈 on 7/8/26.
//

import SwiftUI
import CoreCameraInterface

struct CapturedBottomBar: View {
    let media: String
    let capturedMedia: CapturedMedia?
    
    var onRetake: () -> Void = { }
    var onComplete: (CapturedMedia) -> Void = { _ in }
    
    var body: some View {
        HStack {
            Button {
                onRetake()
            } label: {
                Text("다시 찍기")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Button {
                guard let media = capturedMedia else { return }
                onComplete(media)
            } label: {
                Text("\(media) 사용")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .frame(height: 94)
    }
}
