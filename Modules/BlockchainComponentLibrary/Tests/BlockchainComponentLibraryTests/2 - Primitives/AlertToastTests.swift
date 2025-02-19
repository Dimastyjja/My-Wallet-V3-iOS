// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import BlockchainComponentLibrary
import SnapshotTesting
import SwiftUI
import XCTest

final class AlertToastTests: XCTestCase {

    override func setUp() {
        super.setUp()
        isRecording = false
    }

    func testSnapshot() {
        let view = VStack(spacing: Spacing.baseline) {
            AlertToast_Previews.previews
        }
        .fixedSize()

        assertSnapshot(matching: view, as: .image(layout: .sizeThatFits))
    }
}
