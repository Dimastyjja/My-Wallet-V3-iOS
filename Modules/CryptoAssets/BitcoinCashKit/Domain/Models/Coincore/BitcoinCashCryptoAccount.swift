// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import DIKit
import Localization
import PlatformKit
import RxSwift
import ToolKit

final class BitcoinCashCryptoAccount: CryptoNonCustodialAccount {
    private typealias LocalizedString = LocalizationConstants.Account

    let id: String
    let label: String
    let asset: CryptoCurrency = .bitcoinCash
    let isDefault: Bool

    func createTransactionEngine() -> Any {
        BitcoinOnChainTransactionEngineFactory<BitcoinCashToken>()
    }

    var pendingBalance: Single<MoneyValue> {
        .just(.zero(currency: .bitcoinCash))
    }

    var balance: Single<MoneyValue> {
        balanceService
            .balance(for: xPub)
            .moneyValue
    }

    var actionableBalance: Single<MoneyValue> {
        balance
    }

    var actions: Single<AvailableActions> {
        isFunded
            .map { isFunded -> AvailableActions in
                var base: AvailableActions = [.viewActivity, .receive, .send]
                if isFunded {
                    base.insert(.swap)
                }
                return base
            }
    }

    var receiveAddress: Single<ReceiveAddress> {
        let receiveAddress: Single<String> = bridge.receiveAddress(forXPub: id)
        let account: Single<BitcoinCashWalletAccount> = bridge
            .wallets
            .map { [xPub] wallets in
                wallets.filter { $0.publicKey == xPub }
            }
            .map { accounts -> BitcoinCashWalletAccount in
                guard let account = accounts.first else {
                    throw PlatformKitError.illegalStateException(message: "Expected a BitcoinCashWalletAccount")
                }
                return account
            }

        return Single.zip(receiveAddress, account)
            .map { [label, onTxCompleted] (address, account) -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinCashToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted,
                    index: Int32(account.index)
                )
            }
    }

    private let xPub: XPub
    private let hdAccountIndex: Int
    private let exchangeService: PairExchangeServiceAPI
    private let balanceService: BalanceServiceAPI
    private let bridge: BitcoinCashWalletBridgeAPI

    init(xPub: XPub,
         label: String?,
         isDefault: Bool,
         hdAccountIndex: Int,
         exchangeProviding: ExchangeProviding = resolve(),
         balanceService: BalanceServiceAPI = resolve(tag: BitcoinChainCoin.bitcoinCash),
         bridge: BitcoinCashWalletBridgeAPI = resolve()) {
        self.xPub = xPub
        self.id = xPub.address
        self.label = label ?? CryptoCurrency.bitcoinCash.defaultWalletName
        self.isDefault = isDefault
        self.hdAccountIndex = hdAccountIndex
        self.exchangeService = exchangeProviding[.bitcoinCash]
        self.balanceService = balanceService
        self.bridge = bridge
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        switch action {
        case .receive,
             .send,
             .viewActivity:
            return .just(true)
        case .deposit,
             .sell,
             .withdraw:
            return .just(false)
        case .swap:
            return isFunded
        }
    }

    func balancePair(fiatCurrency: FiatCurrency) -> Observable<MoneyValuePair> {
        exchangeService.fiatPrice
            .flatMapLatest(weak: self) { (self, exchangeRate) in
                self.balance
                    .map { balance -> MoneyValuePair in
                        try MoneyValuePair(base: balance, exchangeRate: exchangeRate.moneyValue)
                    }
                    .asObservable()
            }
    }

    func updateLabel(_ newLabel: String) -> Completable {
        bridge.update(accountIndex: hdAccountIndex, label: newLabel)
    }
}
