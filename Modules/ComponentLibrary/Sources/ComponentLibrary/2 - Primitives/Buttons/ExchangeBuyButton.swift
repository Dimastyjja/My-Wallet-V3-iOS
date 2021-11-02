// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// ExchangeBuyButton from the Figma Component Library.
///
///
/// # Usage:
///
/// `ExchangeBuyButton(title: "Tap me") { print("button did tap") }`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=3%3A367)

public struct ExchangeBuyButton: View, PillButton {

    let title: String
    let action: () -> Void
    let isLoading: Bool

    let colorSet = PillButtonColorSet(
        enabledState: PillButtonStyle.ColorSet(
            foreground: Color.dynamicColor(
                light: .semantic.white,
                dark: .semantic.white
            ),
            background: Color.dynamicColor(
                light: .semantic.success,
                dark: .semantic.successMuted
            ),
            border: Color.dynamicColor(
                light: .semantic.success,
                dark: .semantic.successMuted
            )
        ),
        pressedState: PillButtonStyle.ColorSet(
            foreground: .semantic.white,
            background: .semantic.success,
            border: .semantic.success
        ),
        disabledState: PillButtonStyle.ColorSet(
            foreground: Color.dynamicColor(
                light: .semantic.white.opacity(0.7),
                dark: .semantic.white.opacity(0.4)
            ),
            background: Color.dynamicColor(
                light: .semantic.successMuted,
                dark: .semantic.success
            ),
            border: Color.dynamicColor(
                light: .semantic.successMuted,
                dark: .semantic.success
            )
        ),
        progressViewRail: Color.semantic.white.opacity(0.8),
        progressViewTrack: Color.semantic.white.opacity(0.25)
    )

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        makeBody()
    }
}

struct ExchangeBuyButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ExchangeBuyButton(title: "Enabled", action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Enabled")

            ExchangeBuyButton(title: "Disabled", action: {})
                .disabled(true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Disabled")

            ExchangeBuyButton(title: "Loading", isLoading: true, action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Loading")
        }
        .padding()
    }
}