// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAppUI
import FeatureDebugUI
import PlatformKit
import ToolKit

extension AppEnvironment {
    static var live: AppEnvironment {
        AppEnvironment(
            loadingViewPresenter: resolve(),
            onboardingSettings: resolve(),
            blurEffectHandler: resolve(),
            cacheSuite: resolve(),
            remoteNotificationServiceContainer: resolve(),
            certificatePinner: resolve(),
            siftService: resolve(),
            alertViewPresenter: resolve(),
            deeplinkAppHandler: resolve(),
            deeplinkHandler: resolve(),
            deeplinkRouter: resolve(),
            backgroundAppHandler: resolve(),
            portfolioSyncingService: resolve(),
            mobileAuthSyncService: resolve(),
            resetPasswordService: resolve(),
            accountRecoveryService: resolve(),
            featureFlagsService: resolve(),
            internalFeatureService: resolve(),
            fiatCurrencySettingsService: resolve(),
            supportedAssetsRemoteService: resolve(),
            customerSupportChatService: resolve(),
            sharedContainer: .default,
            analyticsRecorder: resolve(),
            crashlyticsRecorder: resolve(tag: "CrashlyticsRecorder"),
            coincore: resolve(),
            erc20CryptoAssetService: resolve(),
            walletManager: resolve(),
            walletUpgradeService: resolve(),
            walletRepoPersistence: resolve(),
            exchangeRepository: ExchangeAccountRepository(),
            appFeatureConfigurator: resolve(),
            blockchainSettings: .shared,
            credentialsStore: resolve(),
            urlSession: resolve(),
            mainQueue: .main,
            appStoreOpener: resolve(),
            buildVersionProvider: Bundle.versionAndBuildNumber
        )
    }
}
