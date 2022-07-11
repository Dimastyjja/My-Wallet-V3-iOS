// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import FeatureCardIssuingDomain
import SwiftUI
import UIKit

public protocol CardIssuingBuilderAPI: AnyObject {

    func makeIntroViewController(
        address: AnyPublisher<Card.Address, CardOrderingError>,
        onComplete: @escaping (CardOrderingResult) -> Void
    ) -> UIViewController

    func makeIntroView(
        address: AnyPublisher<Card.Address, CardOrderingError>,
        onComplete: @escaping (CardOrderingResult) -> Void
    ) -> AnyView

    func makeManagementViewController(
        onComplete: @escaping () -> Void
    ) -> UIViewController

    func makeManagementView(
        onComplete: @escaping () -> Void
    ) -> AnyView
}

final class CardIssuingBuilder: CardIssuingBuilderAPI {

    private let accountModelProvider: AccountProviderAPI
    private let cardService: CardServiceAPI
    private let productService: ProductsServiceAPI
    private let supportRouter: SupportRouterAPI
    private let topUpRouter: TopUpRouterAPI

    init(
        accountModelProvider: AccountProviderAPI,
        cardService: CardServiceAPI,
        productService: ProductsServiceAPI,
        supportRouter: SupportRouterAPI,
        topUpRouter: TopUpRouterAPI
    ) {
        self.accountModelProvider = accountModelProvider
        self.cardService = cardService
        self.productService = productService
        self.supportRouter = supportRouter
        self.topUpRouter = topUpRouter
    }

    func makeIntroViewController(
        address: AnyPublisher<Card.Address, CardOrderingError>,
        onComplete: @escaping (CardOrderingResult) -> Void
    ) -> UIViewController {

        UIHostingController(
            rootView: makeIntroView(
                address: address,
                onComplete: onComplete
            )
        )
    }

    func makeIntroView(
        address: AnyPublisher<Card.Address, CardOrderingError>,
        onComplete: @escaping (CardOrderingResult) -> Void
    ) -> AnyView {

        let env = CardOrderingEnvironment(
            mainQueue: .main,
            cardService: cardService,
            productsService: productService,
            address: address,
            onComplete: onComplete
        )

        let store = Store<CardOrderingState, CardOrderingAction>(
            initialState: .init(),
            reducer: cardOrderingReducer,
            environment: env
        )

        return AnyView(CardIssuingIntroView(store: store))
    }

    func makeManagementViewController(
        onComplete: @escaping () -> Void
    ) -> UIViewController {

        UIHostingController(
            rootView: makeManagementView(
                onComplete: onComplete
            )
        )
    }

    func makeManagementView(
        onComplete: @escaping () -> Void
    ) -> AnyView {

        let env = CardManagementEnvironment(
            accountModelProvider: accountModelProvider,
            cardService: cardService,
            mainQueue: .main,
            productsService: productService,
            supportRouter: supportRouter,
            topUpRouter: topUpRouter,
            close: onComplete
        )

        let store = Store<CardManagementState, CardManagementAction>(
            initialState: .init(),
            reducer: cardManagementReducer,
            environment: env
        )

        return AnyView(CardManagementView(store: store))
    }
}