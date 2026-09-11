//
//  ImageLoaderEnvironment.swift
//  NJPackage
//
//  Created by 정지훈 on 7/21/26.
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var imageLoaderClient = ImageLoaderClient.unimplemented
}
