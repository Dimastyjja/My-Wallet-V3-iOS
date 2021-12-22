// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import ComponentLibrary
import SnapshotTesting
import SwiftUI
import XCTest

final class LargeSegmentedControlTests: XCTestCase {

    func testSnapshot() {
        let view = VStack(spacing: Spacing.baseline) {
            LargeSegmentedControl_Previews.previews
        }
        .frame(width: 320)
        .fixedSize()

        assertSnapshots(
            matching: view,
            as: [
                .image(layout: .sizeThatFits, traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(layout: .sizeThatFits, traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: false
        )
    }

    func testRightToLeft() {
        let view = VStack(spacing: Spacing.baseline) {
            LargeSegmentedControl_Previews.previews
        }
        .environment(\.layoutDirection, .rightToLeft)
        .frame(width: 320)
        .fixedSize()

        assertSnapshot(matching: view, as: .image, record: false)
    }
}
