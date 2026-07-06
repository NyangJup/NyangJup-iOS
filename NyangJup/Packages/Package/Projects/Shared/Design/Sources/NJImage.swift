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
    public static let cherryBlossomTree = NJImageAsset(resource: .Images.cherryBlossomTree)
    public static let fenceSegment = NJImageAsset(resource: .Images.fenceSegment)
    public static let flowerPatch = NJImageAsset(resource: .Images.flowerPatch)
    public static let flowerPlanter = NJImageAsset(resource: .Images.flowerPlanter)
    public static let lampPost = NJImageAsset(resource: .Images.lampPost)
    public static let leafyTree = NJImageAsset(resource: .Images.leafyTree)
    public static let map = NJImageAsset(resource: .Images.map)
    public static let parkObjectsSheet = NJImageAsset(resource: .Images.parkObjectsSheet)
    public static let parkObjectsSheetChromakey = NJImageAsset(resource: .Images.parkObjectsSheetChromakey)
    public static let pineTree = NJImageAsset(resource: .Images.pineTree)
    public static let rockCluster = NJImageAsset(resource: .Images.rockCluster)
    public static let roundBush = NJImageAsset(resource: .Images.roundBush)
    public static let smallPond = NJImageAsset(resource: .Images.smallPond)
    public static let woodenBench = NJImageAsset(resource: .Images.woodenBench)
    public static let woodenSign = NJImageAsset(resource: .Images.woodenSign)
}
