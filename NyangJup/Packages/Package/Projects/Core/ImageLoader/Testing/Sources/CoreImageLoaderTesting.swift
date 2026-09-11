import UIKit

import CoreImageLoaderInterface

public extension ImageLoaderClient {
    static let test = Self { _, _, _, _ in
        UIImage(systemName: "photo") ?? UIImage()
    }
}
