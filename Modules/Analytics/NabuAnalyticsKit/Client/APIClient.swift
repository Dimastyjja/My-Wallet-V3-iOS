// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import NetworkKit

class APIClient: EventSendingAPI {
    
    private enum Path {
        static let transactions = ["events", "publish"]
    }
    
    // MARK: - Properties
    
    private let requestBuilder: RequestBuilder
    private let networkAdapter: NetworkAdapterAPI

    // MARK: - Setup
    
    init(networkAdapter: NetworkAdapterAPI = resolve(),
         requestBuilder: RequestBuilder = resolve()) {
        self.networkAdapter = networkAdapter
        self.requestBuilder = requestBuilder
    }
    
    func publish(events: EventsWrapper) -> AnyPublisher<Void, NetworkError> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        guard let body = try? jsonEncoder.encode(events) else {
            fatalError("Error encoding analytics event body.")
        }
        guard let request = requestBuilder.post(path: Path.transactions, body: body) else {
            fatalError("Error creating analytics event request.")
        }
        return networkAdapter.performOptional(request: request)
    }
}
