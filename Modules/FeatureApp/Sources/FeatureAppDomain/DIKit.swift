// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import FeatureAuthenticationDomain
import FeatureCardPaymentDomain
import FeatureSettingsDomain
import FeatureWithdrawalLocksData
import FeatureWithdrawalLocksDomain
import PlatformKit

extension DependencyContainer {

    // MARK: - FeatureAppDomain Module

    public static var featureAppDomain = module {

        single { () -> AnalyticsKit.TokenProvider in
            let tokenRepository: NabuTokenRepositoryAPI = DIKit.resolve()
            return { tokenRepository.sessionToken } as AnalyticsKit.TokenProvider
        }

        single { () -> FeatureAuthenticationDomain.NabuUserEmailProvider in
            let service: SettingsServiceAPI = DIKit.resolve()
            return { () -> AnyPublisher<String, Error> in
                service
                    .singleValuePublisher
                    .map(\.email)
                    .eraseError()
                    .eraseToAnyPublisher()
            } as FeatureAuthenticationDomain.NabuUserEmailProvider
        }

        // MARK: Withdrawal Lock

        factory {
            MoneyValueFormatterAdapter() as MoneyValueFormatterAPI
        }

        factory {
            FiatCurrencyCodeProviderAdapter() as FiatCurrencyCodeProviderAPI
        }

        factory {
            ApplePayAdapter(
                app: DIKit.resolve(),
                fiatCurrencyService: DIKit.resolve(),
                featureFlagsService: DIKit.resolve(),
                eligibleMethodsClient: DIKit.resolve(),
                tiersService: DIKit.resolve()
            ) as ApplePayEligibleServiceAPI
        }

        factory {
            CardIssuingAdapter(
                app: DIKit.resolve(),
                featureFlagsService: DIKit.resolve(),
                productsService: DIKit.resolve(),
                cardService: DIKit.resolve()
            ) as CardIssuingAdapterAPI
        }

        factory {
            ReferralsAdapter(
                featureFlagsService: DIKit.resolve(),
                referralService: DIKit.resolve()
            ) as ReferralAdapterAPI
        }
    }
}
