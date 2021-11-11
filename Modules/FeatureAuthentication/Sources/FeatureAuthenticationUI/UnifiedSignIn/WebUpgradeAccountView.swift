// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureAuthenticationDomain
import SwiftUI
import UIComponentsKit

struct WebUpgradeAccountView: View {

    private enum MessageHandlers {
        /// Message handlers name for unified sign in communication
        static let connectionStatus = "connectionStatusHandler"
        static let credentials = "credentialsHandler"
    }

    private static let url = "\(Constants.HostURL.loginOnWeb)?product=wallet&platform=ios"

    private let connectionStatusCallback: (String) -> Void
    private let credentialsCallback: (String) -> Void
    @Binding private var sendMessage: String

    init(
        sendMessage: Binding<String>,
        connectionStatusCallback: @escaping (String) -> Void,
        credentialsCallback: @escaping (String) -> Void
    ) {
        _sendMessage = sendMessage
        self.connectionStatusCallback = connectionStatusCallback
        self.credentialsCallback = credentialsCallback
    }

    var body: some View {
        WebView(
            sendMessage: $sendMessage,
            url: URL(string: WebUpgradeAccountView.url)!,
            messageHandlers: [
                MessageHandlers.connectionStatus: connectionStatusCallback,
                MessageHandlers.credentials: credentialsCallback
            ]
        )
        .navigationBarHidden(true)
    }
}

#if DEBUG
struct WebUpgradeAccountView_Previews: PreviewProvider {
    static var previews: some View {
        WebUpgradeAccountView(
            sendMessage: .constant("Test Message"),
            connectionStatusCallback: { print($0) },
            credentialsCallback: { print($0) }
        )
    }
}
#endif
