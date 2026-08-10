//
//  AdsType.swift
//  NJPackage
//
//  Created by 정지훈 on 8/7/26.
//

import Foundation

public enum AdsType {
    case reward
    case native
}

extension AdsType {
    package var adsId: String {
        switch self {
        case .reward: Bundle.main.infoDictionary?["REWARD_AD_ID"] as? String ?? ""
        case .native: Bundle.main.infoDictionary?["NATIVE_AD_ID"] as? String ?? ""
        }
    }
}
