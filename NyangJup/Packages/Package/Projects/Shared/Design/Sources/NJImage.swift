//
//  NJImage.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SwiftUI

import UIKit

public struct NJImageAsset: Sendable {
    public let resource: ImageResource

    public var image: Image {
        Image(resource)
    }

    public var uiImage: UIImage {
        UIImage(resource: resource)
    }
}

public enum NJImage {
    public static let abyssinian = NJImageAsset(resource: .Images.abyssinian)
    public static let americanShorthair = NJImageAsset(resource: .Images.americanShorthair)
    public static let bengal = NJImageAsset(resource: .Images.bengal)
    public static let britishShorthair = NJImageAsset(resource: .Images.britishShorthair)
    public static let cherryBlossomTree = NJImageAsset(resource: .Images.cherryBlossomTree)
    public static let fenceSegment = NJImageAsset(resource: .Images.fenceSegment)
    public static let flowerPatch = NJImageAsset(resource: .Images.flowerPatch)
    public static let flowerPlanter = NJImageAsset(resource: .Images.flowerPlanter)
    public static let lampPost = NJImageAsset(resource: .Images.lampPost)
    public static let leafyTree = NJImageAsset(resource: .Images.leafyTree)
    public static let koreanCalico = NJImageAsset(resource: .Images.koreanCalico)
    public static let koreanShorthair = NJImageAsset(resource: .Images.koreanShorthair)
    public static let maineCoon = NJImageAsset(resource: .Images.maineCoon)
    public static let map = NJImageAsset(resource: .Images.map)
    public static let norwegianForest = NJImageAsset(resource: .Images.norwegianForest)
    public static let parkObjectsSheet = NJImageAsset(resource: .Images.parkObjectsSheet)
    public static let parkObjectsSheetChromakey = NJImageAsset(resource: .Images.parkObjectsSheetChromakey)
    public static let pineTree = NJImageAsset(resource: .Images.pineTree)
    public static let persian = NJImageAsset(resource: .Images.persian)
    public static let ragdoll = NJImageAsset(resource: .Images.ragdoll)
    public static let rockCluster = NJImageAsset(resource: .Images.rockCluster)
    public static let roundBush = NJImageAsset(resource: .Images.roundBush)
    public static let scottishFold = NJImageAsset(resource: .Images.scottishFold)
    public static let siamese = NJImageAsset(resource: .Images.siamese)
    public static let smallPond = NJImageAsset(resource: .Images.smallPond)
    public static let sphynx = NJImageAsset(resource: .Images.sphynx)
    public static let turkishAngora = NJImageAsset(resource: .Images.turkishAngora)
    public static let tuxedo = NJImageAsset(resource: .Images.tuxedo)
    public static let woodenBench = NJImageAsset(resource: .Images.woodenBench)
    public static let woodenSign = NJImageAsset(resource: .Images.woodenSign)
    public static let generateBackground = NJImageAsset(resource: .Images.generateBackground)
}
