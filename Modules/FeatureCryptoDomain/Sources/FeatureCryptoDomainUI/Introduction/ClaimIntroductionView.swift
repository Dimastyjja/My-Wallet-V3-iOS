// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import Combine
import ComposableArchitecture
import ComposableNavigation
import FeatureCryptoDomainDomain
import Localization
import SwiftUI
import ToolKit

// MARK: - ComposableArchitecture

enum ClaimIntroductionRoute: NavigationRoute {
    case benefits
    case searchDomain

    @ViewBuilder
    func destination(in store: Store<ClaimIntroductionState, ClaimIntroductionAction>) -> some View {
        switch self {
        case .benefits:
            ClaimBenefitsView()
        case .searchDomain:
            IfLetStore(
                store.scope(
                    state: \.searchState,
                    action: ClaimIntroductionAction.searchAction
                ),
                then: SearchCryptoDomainView.init(store:)
            )
        }
    }
}

enum ClaimIntroductionAction: NavigationAction {
    case route(RouteIntent<ClaimIntroductionRoute>?)
    case searchAction(SearchCryptoDomainAction)
}

struct ClaimIntroductionState: NavigationState {
    var route: RouteIntent<ClaimIntroductionRoute>?
    var searchState: SearchCryptoDomainState?
    var isModalOpen: Bool = true
}

struct ClaimIntroductionEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let searchDomainRepository: SearchDomainRepositoryAPI
    let orderDomainRepository: OrderDomainRepositoryAPI
    let userInfoProvider: () -> AnyPublisher<OrderDomainUserInfo, Error>
}

let claimIntroductionReducer = Reducer.combine(
    searchCryptoDomainReducer
        .optional()
        .pullback(
            state: \.searchState,
            action: /ClaimIntroductionAction.searchAction,
            environment: {
                SearchCryptoDomainEnvironment(
                    mainQueue: $0.mainQueue,
                    searchDomainRepository: $0.searchDomainRepository,
                    orderDomainRepository: $0.orderDomainRepository,
                    userInfoProvider: $0.userInfoProvider
                )
            }
        ),
    Reducer<ClaimIntroductionState, ClaimIntroductionAction, ClaimIntroductionEnvironment> {
        state, action, _ in
        switch action {
        case .route(let route):
            if let routeValue = route?.route {
                switch routeValue {
                case .searchDomain:
                    state.searchState = .init()
                case .benefits:
                    break
                }
            }
            return .none
        case .searchAction(.checkoutAction(.dismissFlow)):
            state.isModalOpen = false
            return .none
        case .searchAction:
            return .none
        }
    }
    .routing()
)

// MARK: - ClaimIntroductionView

public final class ClaimIntroductionHositingController: UIViewController {

    private let store: Store<ClaimIntroductionState, ClaimIntroductionAction>
    private let viewStore: ViewStore<ClaimIntroductionState, ClaimIntroductionAction>

    private let mainQueue: AnySchedulerOf<DispatchQueue>
    private let searchDomainRepository: SearchDomainRepositoryAPI
    private let orderDomainRepository: OrderDomainRepositoryAPI
    private let userInfoProvider: () -> AnyPublisher<OrderDomainUserInfo, Error>

    private let contentView: UIHostingController<ClaimIntroductionView>

    private var cancellables = Set<AnyCancellable>()

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        searchDomainRepository: SearchDomainRepositoryAPI,
        orderDomainRepository: OrderDomainRepositoryAPI,
        userInfoProvider: @escaping () -> AnyPublisher<OrderDomainUserInfo, Error>
    ) {
        self.mainQueue = mainQueue
        self.searchDomainRepository = searchDomainRepository
        self.orderDomainRepository = orderDomainRepository
        self.userInfoProvider = userInfoProvider
        store = .init(
            initialState: .init(),
            reducer: claimIntroductionReducer,
            environment: .init(
                mainQueue: mainQueue,
                searchDomainRepository: searchDomainRepository,
                orderDomainRepository: orderDomainRepository,
                userInfoProvider: userInfoProvider
            )
        )
        viewStore = ViewStore(store)
        contentView = UIHostingController(rootView: ClaimIntroductionView(store: store))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView.view)
        addChild(contentView)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        viewStore
            .publisher
            .isModalOpen
            .sink { [weak self] shouldOpen in
                if !shouldOpen {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
            .store(in: &cancellables)
    }


    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    public override func viewDidLayoutSubviews() {
        navigationController?.isNavigationBarHidden = true
    }
}

public struct ClaimIntroductionView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureCryptoDomain.ClaimIntroduction
    private typealias Accessibility = AccessibilityIdentifiers.HowItWorks

    private let store: Store<ClaimIntroductionState, ClaimIntroductionAction>

    init(store: Store<ClaimIntroductionState, ClaimIntroductionAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            PrimaryNavigationView {
                VStack(alignment: .center, spacing: Spacing.padding3) {
                    introductionHeader
                        .padding([.top, .leading, .trailing], Spacing.padding3)
                    introductionList
                    Spacer()
                    SmallMinimalButton(title: LocalizedString.promptButton) {
                        viewStore.send(.enter(into: .benefits))
                    }
                    .accessibility(identifier: Accessibility.smallButton)
                    Spacer()
                    Text(LocalizedString.instruction)
                        .typography(.caption1)
                        .foregroundColor(.semantic.overlay)
                        .multilineTextAlignment(.center)
                        .padding([.leading, .trailing], Spacing.padding3)
                        .accessibility(identifier: Accessibility.instructionText)
                    PrimaryButton(title: LocalizedString.goButton) {
                        viewStore.send(.navigate(to: .searchDomain))
                    }
                    .padding([.leading, .trailing], Spacing.padding3)
                    .accessibility(identifier: Accessibility.ctaButton)
                }
                .navigationRoute(in: store)
                .primaryNavigation(title: LocalizedString.title)
            }
        }
    }

    private var introductionHeader: some View {
        VStack(alignment: .center, spacing: Spacing.padding2) {
            Text(LocalizedString.Header.title)
                .typography(.title3)
                .accessibility(identifier: Accessibility.headerTitle)
            Text(LocalizedString.Header.description)
                .typography(.paragraph1)
                .foregroundColor(.semantic.overlay)
                .multilineTextAlignment(.center)
                .accessibility(identifier: Accessibility.headerDescription)
        }
    }

    private var introductionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrimaryDivider()
            PrimaryRow(
                title: LocalizedString.ListView.ChooseDomain.title,
                subtitle: LocalizedString.ListView.ChooseDomain.description,
                leading: {
                    Image("number-one")
                        .resizable()
                        .frame(width: 24, height: 24)
                },
                trailing: { EmptyView() }
            ).padding([.top, .bottom], 10)
            PrimaryDivider()
            PrimaryRow(
                title: LocalizedString.ListView.ClaimDomain.title,
                subtitle: LocalizedString.ListView.ClaimDomain.description,
                leading: {
                    Image("number-two")
                        .resizable()
                        .frame(width: 24, height: 24)
                },
                trailing: { EmptyView() }
            ).padding([.top, .bottom], 10)
            PrimaryDivider()
            PrimaryRow(
                title: LocalizedString.ListView.ReceiveCrypto.title,
                subtitle: LocalizedString.ListView.ReceiveCrypto.description,
                leading: {
                    Image("number-three")
                        .resizable()
                        .frame(width: 24, height: 24)
                },
                trailing: { EmptyView() }
            ).padding([.top, .bottom], 10)
            PrimaryDivider()
        }
        .accessibility(identifier: Accessibility.introductionList)
    }
}

#if DEBUG
@testable import FeatureCryptoDomainData
@testable import FeatureCryptoDomainMock

struct ClaimIntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        ClaimIntroductionView(
            store: .init(
                initialState: .init(),
                reducer: claimIntroductionReducer,
                environment: .init(
                    mainQueue: .main,
                    searchDomainRepository: SearchDomainRepository(
                        apiClient: SearchDomainClient.mock
                    ),
                    orderDomainRepository: OrderDomainRepository(
                        apiClient: OrderDomainClient.mock
                    ),
                    userInfoProvider: { .empty() }
                )
            )
        )
    }
}
#endif
