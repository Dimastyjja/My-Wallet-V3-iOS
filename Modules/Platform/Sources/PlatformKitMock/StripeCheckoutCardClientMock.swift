// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import NabuNetworkError
import PlatformKit

private class CardClientMock: CardClientAPI {
    private let cardClient: CardClientAPI

    init(cardClient: CardClientAPI = resolve()) {
        self.cardClient = cardClient
    }

    var cardList: AnyPublisher<[CardPayload], NabuNetworkError> {
        cardClient.cardList
    }

    func chargeCard(by id: String) -> AnyPublisher<Void, NabuNetworkError> {
        cardClient.chargeCard(by: id)
    }

    func deleteCard(by id: String) -> AnyPublisher<Void, NabuNetworkError> {
        cardClient.deleteCard(by: id)
    }

//    func activateCard(by id: String, url: String) -> AnyPublisher<ActivateCardResponse.Partner, NabuNetworkError> {
//        let link = "https://api.sandbox.checkout.com/sessions-interceptor/sid_jb6trca5nsgufow6y2mrvhcteq"
//        let partner: ActivateCardResponse.Partner = .cardAcquirer(.init(cardAcquirerName: .checkout,
//                                                                        cardAcquirerAccountCode: "checkout_uk",
//                                                                        apiUserID: nil,
//                                                                        apiToken: nil,
//                                                                        paymentLink: link,
//                                                                        paymentState: nil,
//                                                                        paymentReference: nil,
//                                                                        orderReference: nil,
//                                                                        clientSecret: nil,
//                                                                        publishableKey: "pk_sbox_eiq2rsadi5eambtzil662iccmil"))
//
//        return .just(partner)
//    }

    func activateCard(by id: String, url: String) -> AnyPublisher<ActivateCardResponse.Partner, NabuNetworkError> {
        let pk = "pk_test_51JhAakHxBe1tOCzxhX2cvybhcCPMMXfQQghkI7X9VEUFMTyLvcyLVFXSkM9bjsynKmRRwLwkalcPrWJeGaNriU6S00x8XQ9VLX"
        let partner: ActivateCardResponse.Partner = .cardAcquirer(.init(
            cardAcquirerName: .stripe,
            cardAcquirerAccountCode: "stripe_uk",
            apiUserID: nil,
            apiToken: nil,
            paymentLink: nil,
            paymentState: nil,
            paymentReference: nil,
            orderReference: nil,
            clientSecret: "pi_3JxYDPHxBe1tOCzx0eL6Zo8u_secret_jgjGD59uSZZ4Hgc8QodCpIYwx",
            publishableKey: pk
        ))

        return .just(partner)
    }

    func getCard(by id: String) -> AnyPublisher<CardPayload, NabuNetworkError> {
        cardClient.getCard(by: id)
    }

    func add(
        for currency: String,
        email: String,
        billingAddress: CardPayload.BillingAddress,
        paymentMethodTokens: [String: String]
    ) -> AnyPublisher<CardPayload, NabuNetworkError> {
        .just(CardPayload(identifier: "", partner: .stripe, address: nil, currency: "GBP", state: .active, card: nil, additionDate: ""))
    }
}