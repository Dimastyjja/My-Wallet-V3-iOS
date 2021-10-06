// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import SwiftUI

extension CurrencyType {

    public var logoResource: ImageResource {
        switch self {
        case .crypto(let currency):
            return currency.logoResource
        case .fiat(let currency):
            return currency.logoResource
        }
    }

    public var brandColor: SwiftUI.Color {
        .init(brandUIColor)
    }

    public var brandUIColor: UIColor {
        switch self {
        case .crypto(let currency):
            return currency.brandUIColor
        case .fiat(let currency):
            return currency.brandColor
        }
    }
}
