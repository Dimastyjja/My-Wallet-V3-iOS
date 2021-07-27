// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import AuthenticationUIKit
import ComposableArchitecture
@testable import ToolKit
import XCTest

final class WelcomeReducerTests: XCTestCase {

    private var dummyUserDefaults: UserDefaults!
    private var mockInternalFeatureFlagService: InternalFeatureFlagServiceAPI!
    private var mockMainQueue: TestSchedulerOf<DispatchQueue>!
    private var testStore: TestStore<
        WelcomeState,
        WelcomeState,
        WelcomeAction,
        WelcomeAction,
        WelcomeEnvironment
    >!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockMainQueue = DispatchQueue.test
        dummyUserDefaults = UserDefaults(suiteName: "welcome.reducer.tests.defaults")!
        mockInternalFeatureFlagService = InternalFeatureFlagService(defaultsProvider: { dummyUserDefaults })
        mockInternalFeatureFlagService.enable(.disableGUIDLogin)
        testStore = TestStore(
            initialState: .init(),
            reducer: welcomeReducer,
            environment: WelcomeEnvironment(
                mainQueue: mockMainQueue.eraseToAnyScheduler(),
                deviceVerificationService: MockDeviceVerificationService(),
                featureFlags: mockInternalFeatureFlagService,
                buildVersionProvider: { "Test Version" }
            )
        )
    }

    override func tearDownWithError() throws {
        mockMainQueue = nil
        testStore = nil
        mockInternalFeatureFlagService = nil
        dummyUserDefaults.removeSuite(named: "welcome.reducer.tests.defaults")
        try super.tearDownWithError()
    }

    func test_verify_initial_state_is_correct() {
        let state = WelcomeState()
        XCTAssertNotNil(state.emailLoginState)
    }

    func test_start_updates_the_build_version() {
        testStore.send(.start) { state in
            state.buildVersion = "Test Version"
        }
    }

    func test_start_shows_manual_pairing_when_feature_flag_is_not_enabled() {
        mockInternalFeatureFlagService.disable(.disableGUIDLogin)
        testStore.send(.start) { state in
            state.buildVersion = "Test Version"
            state.manualPairingEnabled = true
        }
    }

    func test_present_screen_flow_updates_screen_flow() {
        let screenFlows: [WelcomeState.ScreenFlow] = [
            .welcomeScreen,
            .createWalletScreen,
            .emailLoginScreen,
            .recoverWalletScreen
        ]
        screenFlows.forEach { screenFlow in
            testStore.send(.presentScreenFlow(screenFlow)) { state in
                state.screenFlow = screenFlow
            }
        }
    }

    func test_close_email_login_should_reset_state() {
        testStore.send(.emailLogin(.closeButtonTapped)) { state in
            state.screenFlow = .welcomeScreen
            XCTAssertNotNil(state.emailLoginState)
        }
    }
}