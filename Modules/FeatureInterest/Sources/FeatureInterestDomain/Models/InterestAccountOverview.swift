// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

public struct InterestAccountOverview: Equatable {

    public var currency: CurrencyType {
        interestAccountRate
            .cryptoCurrency
            .currencyType
    }

    public var balance: MoneyValue {
        let zero: MoneyValue = .zero(currency: currency)
        return balanceDetails?.moneyBalance ?? zero
    }

    public var totalEarned: MoneyValue {
        let zero: MoneyValue = .zero(currency: currency)
        return balanceDetails?.moneyTotalInterest ?? zero
    }

    public var ineligibilityReason: InterestAccountIneligibilityReason {
        interestAccountEligibility
            .ineligibilityReason
    }

    public let interestAccountEligibility: InterestAccountEligibility
    public let interestAccountRate: InterestAccountRate
    public let balanceDetails: InterestAccountBalanceDetails?

    public init(
        interestAccountEligibility: InterestAccountEligibility,
        interestAccountRate: InterestAccountRate,
        balanceDetails: InterestAccountBalanceDetails? = nil
    ) {
        self.interestAccountEligibility = interestAccountEligibility
        self.interestAccountRate = interestAccountRate
        self.balanceDetails = balanceDetails
    }
}

extension InterestAccountOverview: Identifiable {
    public var id: String {
        "\(interestAccountEligibility.currencyType.code)"
    }
}

extension InterestAccountOverview {
    public static func == (
        lhs: InterestAccountOverview,
        rhs: InterestAccountOverview
    ) -> Bool {
        lhs.interestAccountEligibility == rhs.interestAccountEligibility &&
            lhs.balanceDetails == rhs.balanceDetails &&
            lhs.interestAccountRate == rhs.interestAccountRate
    }
}