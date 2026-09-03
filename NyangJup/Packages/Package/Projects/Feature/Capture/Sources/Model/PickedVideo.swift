//
//  PickedVideo.swift
//  NJPackage
//
//  Created by 정지훈 on 9/2/26.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { receivedFile in
            let pathExtension = receivedFile.file.pathExtension.isEmpty
                ? "mov"
                : receivedFile.file.pathExtension
            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(pathExtension)

            try FileManager.default.copyItem(
                at: receivedFile.file,
                to: destinationURL
            )
            return PickedVideo(url: destinationURL)
        }
    }
}
