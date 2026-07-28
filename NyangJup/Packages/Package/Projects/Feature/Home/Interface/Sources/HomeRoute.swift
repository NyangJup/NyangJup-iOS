//
//  HomeRoute.swift
//  NJPackage
//
//  Created by 정지훈 on 7/15/26.
//

import DomainMediaInterface

public enum HomeRoute: Hashable, Sendable {
    case feed(catId: String)
    case relayCat(RelayCat)
}
