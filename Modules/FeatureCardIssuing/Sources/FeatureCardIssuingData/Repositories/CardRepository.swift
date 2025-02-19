// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import Errors
import FeatureCardIssuingDomain
import Foundation
import NetworkKit
import PassKit
import ToolKit

final class CardRepository: CardRepositoryAPI {

    let app: AppProtocol

    private static let marqetaPath = "/marqeta-card/#/"

    private struct AccountKey: Hashable {
        let id: String
    }

    private let client: CardClientAPI
    private let userInfoProvider: UserInfoProviderAPI

    private let baseCardHelperUrl: String

    private let cachedCardValue: CachedValueNew<
        String,
        [Card],
        NabuNetworkError
    >

    private let cachedAccountValue: CachedValueNew<
        AccountKey,
        AccountCurrency,
        NabuNetworkError
    >

    private let accountCache: AnyCache<AccountKey, AccountCurrency>
    private let cardCache: AnyCache<String, [Card]>

    init(
        app: AppProtocol,
        client: CardClientAPI,
        userInfoProvider: UserInfoProviderAPI,
        baseCardHelperUrl: String
    ) {
        self.app = app
        self.client = client
        self.userInfoProvider = userInfoProvider
        self.baseCardHelperUrl = baseCardHelperUrl

        let cardCache: AnyCache<String, [Card]> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()

        cachedCardValue = CachedValueNew(
            cache: cardCache,
            fetch: { _ in
                client.fetchCards()
            }
        )

        self.cardCache = cardCache

        let accountCache: AnyCache<AccountKey, AccountCurrency> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()

        cachedAccountValue = CachedValueNew(
            cache: accountCache,
            fetch: { accountKey in
                client.fetchLinkedAccount(with: accountKey.id)
            }
        )

        self.accountCache = accountCache
    }

    func orderCard(
        product: Product,
        at address: Card.Address,
        with ssn: String
    ) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .orderCard(
                with: .init(productCode: product.productCode, deliveryAddress: address, ssn: ssn)
            )
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func fetchCards() -> AnyPublisher<[Card], NabuNetworkError> {
        cachedCardValue.get(key: #file)
    }

    func fetchCard(with id: String) -> AnyPublisher<Card, NabuNetworkError> {
        client.fetchCard(with: id)
    }

    func delete(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .deleteCard(with: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            }, receiveCompletion: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func helperUrl(for card: Card) -> AnyPublisher<URL, NabuNetworkError> {
        let baseCardHelperUrl = baseCardHelperUrl
        return client
            .generateSensitiveDetailsToken(with: card.id)
            .combineLatest(userInfoProvider.fullName)
            .map { token, fullName in
                Self.buildCardHelperUrl(
                    with: baseCardHelperUrl,
                    token: token,
                    for: card,
                    with: fullName
                )
            }
            .eraseToAnyPublisher()
    }

    func generatePinToken(for card: Card) -> AnyPublisher<String, NabuNetworkError> {
        client.generatePinToken(with: card.id)
    }

    func fetchLinkedAccount(for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError> {
        cachedAccountValue.get(key: AccountKey(id: card.id))
    }

    func update(account: AccountBalance, for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError> {
        client
            .updateAccount(
                with: AccountCurrency(accountCurrency: account.balance.symbol),
                for: card.id
            )
            .flatMap { [accountCache] accountCurrency in
                accountCache
                    .set(accountCurrency, for: AccountKey(id: card.id))
                    .replaceOutput(with: accountCurrency)
            }
            .eraseToAnyPublisher()
    }

    func eligibleAccounts(for card: Card) -> AnyPublisher<[AccountBalance], NabuNetworkError> {
        client.eligibleAccounts(for: card.id)
    }

    func lock(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .lock(cardId: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func unlock(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .unlock(cardId: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func tokenise(
        card: Card,
        with certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) -> AnyPublisher<PKAddPaymentPassRequest, NabuNetworkError> {
        let config = Base64Configuration(
            activationData: isEnabled(blockchain.app.configuration.card.issuing.tokenise.base64.activationData.is.enabled),
            ephemeralPublicKey: isEnabled(blockchain.app.configuration.card.issuing.tokenise.base64.ephemeralPublicKey.is.enabled),
            encryptedPassData: isEnabled(blockchain.app.configuration.card.issuing.tokenise.base64.encryptedPassData.is.enabled)
        )
        return client.tokenise(
            cardId: card.id,
            with: TokeniseCardParameters(
                certificates: certificates,
                nonce: nonce,
                nonceSignature: nonceSignature
            )
        )
        .map {
            PKAddPaymentPassRequest($0, config)
        }
        .eraseToAnyPublisher()
    }

    private func isEnabled(_ tag: Tag.Event) -> Bool {
        guard let value = try? app.remoteConfiguration.get(tag) else {
            return false
        }
        guard let isEnabled = value as? Bool else {
            return false
        }
        return isEnabled
    }

    private static func buildCardHelperUrl(
        with base: String,
        token: String,
        for card: Card,
        with name: String
    ) -> URL {
        let nameParam = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "-"
        return URL(
            string: "\(base)\(Self.marqetaPath)\(token)/\(card.last4)/\(nameParam)"
        )!
    }
}

struct Base64Configuration {
    let activationData: Bool
    let ephemeralPublicKey: Bool
    let encryptedPassData: Bool
}

extension PKAddPaymentPassRequest {

    convenience init(
        _ response: TokeniseCardResponse,
        _ configuration: Base64Configuration
    ) {
        self.init()
        if configuration.activationData {
            activationData = Data(base64Encoded: response.activationData)
        } else {
            activationData = response.activationData.data(using: .utf8)
        }
        if configuration.ephemeralPublicKey {
            ephemeralPublicKey = Data(base64Encoded: response.ephemeralPublicKey)
        } else {
            ephemeralPublicKey = response.ephemeralPublicKey.data(using: .utf8)
        }
        if configuration.encryptedPassData {
            encryptedPassData = Data(base64Encoded: response.encryptedPassData)
        } else {
            encryptedPassData = response.encryptedPassData.data(using: .utf8)
        }
    }
}
