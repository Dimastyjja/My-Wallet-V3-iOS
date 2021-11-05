// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public protocol InterestActivityItemEventRepositoryAPI: AnyObject {
    func fetchInterestActivityItemEventsForCryptoCurrency(
        _ cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<[InterestActivityItemEvent], InterestActivityRepositoryError>
}
