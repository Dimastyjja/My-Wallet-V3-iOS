// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import PlatformKit

public enum EthereumTransactionPublishedError: Error {
    case invalidResponseHash
}

public struct EthereumTransactionPublished: Equatable {

    /// The transaction hash of the published transaction.
    public let transactionHash: String

    init(transactionHash: String) {
        self.transactionHash = transactionHash
    }

    /// Creates a EthereumTransactionPublished.
    ///
    /// This factory method checks that the response transaction hash (`responseHash`) does match the given
    ///  `EthereumTransactionFinalised` transaction hash.
    static func create(
        finalisedTransaction: EthereumTransactionFinalised,
        responseHash: String
    ) -> Result<EthereumTransactionPublished, EthereumTransactionPublishedError> {
        guard finalisedTransaction.transactionHash == responseHash else {
            return .failure(.invalidResponseHash)
        }
        return .success(.init(transactionHash: finalisedTransaction.transactionHash))
    }
}
