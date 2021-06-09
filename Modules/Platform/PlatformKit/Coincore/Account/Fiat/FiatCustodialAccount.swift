// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Localization
import RxSwift
import ToolKit

final class FiatCustodialAccount: FiatAccount {

    let id: String
    let actions: Single<AvailableActions> = .just([.deposit, .viewActivity])
    let isDefault: Bool = true
    let label: String
    let fiatCurrency: FiatCurrency

    var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    var canWithdrawFunds: Single<Bool> {
        /// TODO: Fetch transaction history and filer
        /// for transactions that are `withdrawals` and have a
        /// transactionState of `.pending`.
        /// If there are no items, the user can withdraw funds.
        unimplemented()
    }

    var pendingBalance: Single<MoneyValue> {
        balances
            .map(\.balance?.pending)
            .onNilJustReturn(.zero(currency: currencyType))
    }

    var balance: Single<MoneyValue> {
        balances
            .map(\.balance?.available)
            .onNilJustReturn(.zero(currency: currencyType))
    }

    var actionableBalance: Single<MoneyValue> {
        balance
    }

    var isFunded: Single<Bool> {
        balance.map(\.isPositive)
    }

    private let balanceService: TradingBalanceServiceAPI
    private let exchange: PairExchangeServiceAPI
    private var balances: Single<CustodialAccountBalanceState> {
        balanceService.balance(for: currencyType)
    }

    init(
        fiatCurrency: FiatCurrency,
        balanceService: TradingBalanceServiceAPI = resolve(),
        exchangeProviding: ExchangeProviding = resolve()
    ) {
        id = "FiatCustodialAccount." + fiatCurrency.code
        label = fiatCurrency.defaultWalletName
        self.fiatCurrency = fiatCurrency
        self.balanceService = balanceService
        self.exchange = exchangeProviding[fiatCurrency]
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        actions.map { $0.contains(action) }
    }

    func balancePair(fiatCurrency: FiatCurrency) -> Observable<MoneyValuePair> {
        guard self.fiatCurrency != fiatCurrency else {
            return balance
                .map { balance in
                    MoneyValuePair(base: balance, quote: balance)
                }
                .asObservable()
        }
        return exchange.fiatPrice
            .flatMap(weak: self) { (self, exchangeRate) in
                self.balance
                    .map { balance -> MoneyValuePair in
                        try MoneyValuePair(base: balance, exchangeRate: exchangeRate.moneyValue)
                    }
                    .asObservable()
            }
    }
}
