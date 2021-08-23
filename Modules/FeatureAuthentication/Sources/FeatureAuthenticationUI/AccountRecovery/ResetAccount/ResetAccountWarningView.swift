// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import SwiftUI
import UIComponentsKit

struct ResetAccountWarningView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.ResetAccountWarning

    private enum Layout {
        static let imageSideLength: CGFloat = 72

        static let messageFontSize: CGFloat = 16
        static let messageLineSpacing: CGFloat = 4

        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24
        static let titleTopPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 10
    }

    var body: some View {
        VStack {
            Spacer()
            Image.CircleIcon.resetAccount
                .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                .accessibility(identifier: AccessibilityIdentifiers.ResetAccountWarningScreen.resetAccountImage)

            Text(LocalizedString.Title.resetAccount)
                .textStyle(.title)
                .padding(.top, Layout.titleTopPadding)
                .accessibility(identifier: AccessibilityIdentifiers.ResetAccountWarningScreen.resetAccountTitleText)

            Text(LocalizedString.Message.resetAccount)
                .font(Font(weight: .medium, size: Layout.messageFontSize))
                .foregroundColor(.textSubheading)
                .lineSpacing(Layout.messageLineSpacing)
                .accessibility(identifier: AccessibilityIdentifiers.ResetAccountWarningScreen.resetAccountMessageText)
            Spacer()

            PrimaryButton(title: LocalizedString.Button.continueReset) {
                // TODO: continue reset
            }
            .padding(.bottom, Layout.buttonBottomPadding)
            .accessibility(identifier: AccessibilityIdentifiers.ResetAccountWarningScreen.continueToResetButton)

            SecondaryButton(title: LocalizedString.Button.retryRecoveryPhrase) {
                // TODO: retry
            }
            .accessibility(identifier: AccessibilityIdentifiers.ResetAccountWarningScreen.retryRecoveryPhraseButton)
        }
        .multilineTextAlignment(.center)
        .padding(
            EdgeInsets(
                top: 0,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
        .navigationBarHidden(true)
    }
}

#if DEBUG
struct ResetAccountWarningView_Previews: PreviewProvider {
    static var previews: some View {
        ResetAccountWarningView()
    }
}
#endif