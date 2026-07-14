//
//  CatAppearance.swift
//  NJPackage
//
//  Created by 정지훈 on 7/14/26.
//

import SharedDesign

enum CatAppearance: String, CaseIterable {
    case abyssinian
    case americanShorthair
    case bengal
    case britishShorthair
    case koreanCalico
    case koreanShorthair
    case maineCoon
    case norwegianForest
    case persian
    case ragdoll
    case scottishFold
    case siamese
    case sphynx
    case turkishAngora
    case tuxedo

    var imageAsset: NJImageAsset {
        switch self {
        case .abyssinian: NJImage.abyssinian
        case .americanShorthair: NJImage.americanShorthair
        case .bengal: NJImage.bengal
        case .britishShorthair: NJImage.britishShorthair
        case .koreanCalico: NJImage.koreanCalico
        case .koreanShorthair: NJImage.koreanShorthair
        case .maineCoon: NJImage.maineCoon
        case .norwegianForest: NJImage.norwegianForest
        case .persian: NJImage.persian
        case .ragdoll: NJImage.ragdoll
        case .scottishFold: NJImage.scottishFold
        case .siamese: NJImage.siamese
        case .sphynx: NJImage.sphynx
        case .turkishAngora: NJImage.turkishAngora
        case .tuxedo: NJImage.tuxedo
        }
    }
}
