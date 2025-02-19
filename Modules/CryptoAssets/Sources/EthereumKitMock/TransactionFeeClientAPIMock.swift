// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
@testable import EthereumKit
import MoneyKit

final class TransactionFeeClientAPIMock: TransactionFeeClientAPI {

    var underlyingFees: AnyPublisher<TransactionFeeResponse, NetworkError> = .just(
        .init(
            gasLimit: 21000,
            gasLimitContract: 75000,
            regular: 2,
            priority: 3
        )
    )

    var underlyingNewFees: AnyPublisher<NewTransactionFeeResponse, NetworkError> = .just(
        NewTransactionFeeResponse(
            gasLimit: "21000",
            gasLimitContract: "75000",
            low: "1000000000",
            normal: "2000000000",
            high: "3000000000"
        )
    )

    func fees(
        network: EthereumKit.EVMNetwork,
        contractAddress: String?
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError> {
        underlyingFees
    }

    func newFees(
        network: EVMNetwork,
        contractAddress: String?
    ) -> AnyPublisher<NewTransactionFeeResponse, NetworkError> {
        underlyingNewFees
    }
}
