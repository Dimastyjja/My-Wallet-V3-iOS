//
//  NabuAuthenticationExecutor.swift
//  PlatformKit
//
//  Created by Daniel on 26/06/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxSwift
import ToolKit
import NetworkKit

public protocol NabuAuthenticationExecutorAPI {
    var token: Single<String> { get }
    func authenticate<Response>(singleFunction: @escaping (String) -> Single<Response>) -> Single<Response>
}

public class NabuAuthenticationExecutor: NabuAuthenticationExecutorAPI {
    
    private struct Token {
        let sessionToken: NabuSessionTokenResponse
        let offlineToken: NabuOfflineTokenResponse
    }
    
    @available(*, deprecated, message: "This is deprecated. Don't use this.")
    public var token: Single<String> {
        getToken().map(\.sessionToken.token)
    }
    
    private let store: NabuTokenStore
    private let userCreationClient: UserCreationClientAPI
    private let credentialsRepository: CredentialsRepositoryAPI & NabuOfflineTokenRepositoryAPI
    private let deviceInfo: DeviceInfo
    private let jwtService: JWTServiceAPI
    private let authenticationClient: NabuAuthenticationClientAPI
    private let settingsService: SettingsServiceAPI
    
    private let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    private let semaphore = DispatchSemaphore(value: 1)
    
    public init(userCreationClient: UserCreationClientAPI = UserCreationClient(),
                store: NabuTokenStore = NabuTokenStore(),
                settingsService: SettingsServiceAPI,
                jwtService: JWTServiceAPI,
                authenticationClient: NabuAuthenticationClientAPI = NabuAuthenticationClient(),
                credentialsRepository: CredentialsRepositoryAPI & NabuOfflineTokenRepositoryAPI,
                deviceInfo: DeviceInfo) {
        self.userCreationClient = userCreationClient
        self.store = store
        self.settingsService = settingsService
        self.credentialsRepository = credentialsRepository
        self.jwtService = jwtService
        self.authenticationClient = authenticationClient
        self.deviceInfo = deviceInfo
    }
    
    public func authenticate<Response>(singleFunction: @escaping (String) -> Single<Response>) -> Single<Response> {
        getToken()
            .flatMap(weak: self) { (self, payload) -> Single<Response> in
                singleFunction(payload.sessionToken.token)
                    .catchError(weak: self) { (self, error) -> Single<Response> in
                        self.refreshOrReturnError(
                            error: error,
                            offlineToken: payload.offlineToken,
                            singleFunction: singleFunction
                        )
                    }
            }
    }
    
    // MARK: - Private methods
    
    private func getToken() -> Single<Token> {
        Single.zip(store.sessionTokenDataSingle, credentialsRepository.offlineTokenResponse)
            .map { payload -> (sessionToken: NabuSessionTokenResponse?, offlineToken: NabuOfflineTokenResponse) in
                let (sessionToken, offlineToken) = payload

                return (sessionToken: sessionToken, offlineToken: offlineToken)
            }
            .catchError(weak: self) { (self, _) -> Single<(sessionToken: NabuSessionTokenResponse?, offlineToken: NabuOfflineTokenResponse)> in
                self.fetchTokens()
                    .map { token -> (sessionToken: NabuSessionTokenResponse?, offlineToken: NabuOfflineTokenResponse) in
                        (sessionToken: token.sessionToken, offlineToken: token.offlineToken)
                    }
            }
            .flatMap(weak: self) { (self, payload) -> Single<Token> in
                guard let token = payload.sessionToken else {
                    return self.fetchTokens()
                }
                return .just(Token(sessionToken: token, offlineToken: payload.offlineToken))
            }
    }
    
    private func fetchTokens() -> Single<Token> {
        let tokenSingle = createUserIfNeeded()
                .observeOn(scheduler)
                .flatMap(weak: self) { (self, offlineToken) -> Single<Token> in
                    self.currentToken(offlineToken: offlineToken)
                        .map { Token(sessionToken: $0, offlineToken: offlineToken) }
                }
        return Single
            .create(weak: self) { (self, observer) -> Disposable in
                self.semaphore.wait()
                let disposable = tokenSingle.subscribe { event in
                    switch event {
                    case .error(let error):
                        observer(.error(error))
                    case .success(let payload):
                        observer(.success(payload))
                    }
                }
                return Disposables.create {
                    disposable.dispose()
                    self.semaphore.signal()
                }
            }
            .subscribeOn(scheduler)
    }
    
    private func currentToken(offlineToken: NabuOfflineTokenResponse) -> Single<NabuSessionTokenResponse> {
        store.requiresRefresh
            .flatMap(weak: self) { (self, requiresRefresh) ->  Single<NabuSessionTokenResponse> in
                guard !requiresRefresh else {
                    return self.refreshToken(offlineToken: offlineToken)
                }
                return self.store.sessionTokenDataSingle
                    .map { sessionToken in
                        guard let sessionToken = sessionToken else {
                            throw MissingCredentialsError.sessionToken
                        }
                        return sessionToken
                    }
            }
            
    }

    private func refreshOrReturnError<Response>(error: Error,
                                                offlineToken: NabuOfflineTokenResponse,
                                                singleFunction: @escaping (String) -> Single<Response>) -> Single<Response> {
        unauthenticated(error: error)
            .flatMap(weak: self) { (self, unauthenticated) -> Single<Response> in
                guard unauthenticated else {
                    return Single.error(error)
                }
                return self.clearAccessToken()
                    .flatMapSingle {
                        self.refreshToken(offlineToken: offlineToken)
                            .flatMap { offlineToken -> Single<Response> in
                                singleFunction(offlineToken.token)
                            }
                    }
            }
    }
    
    private func refreshToken(offlineToken: NabuOfflineTokenResponse) -> Single<NabuSessionTokenResponse> {
        getSessionToken(offlineTokenResponse: offlineToken)
            .flatMap(weak: self) { (self, sessionTokenResponse) in
                self.store.store(sessionTokenResponse)
            }
            .catchError(weak: self) { (self, error) -> Single<NabuSessionTokenResponse> in
                self.recoverOrReturnError(error: error, offlineToken: offlineToken)
            }
    }
    
    private func unauthenticated(error: Error) -> Single<Bool> {
        guard let error = NabuAPIError(error: error) else {
            return .just(false)
        }
        return .just(error == .tokenExpired)
    }
    
    private func clearAccessToken() -> Completable {
        store.invalidate()
    }
    
    private func getSessionToken(offlineTokenResponse: NabuOfflineTokenResponse) -> Single<NabuSessionTokenResponse> {
        let email = settingsService.valueSingle
            .map { $0.email }

        let guid = credentialsRepository.guid
            .map { guid -> String in
                guard let guid = guid else { throw MissingCredentialsError.guid }
                return guid
            }
        
        return Single
            .zip(email, guid)
            .map { (email: $0.0, guid: $0.1) }
            .flatMap(weak: self) { (self, payload) in
                self.authenticationClient
                    .sessionToken(
                        for: payload.guid,
                        userToken: offlineTokenResponse.token,
                        userIdentifier: offlineTokenResponse.userId,
                        deviceId: self.deviceInfo.uuidString,
                        email: payload.email
                    )
            }
    }
    
    private func recoverOrReturnError(error: Error, offlineToken: NabuOfflineTokenResponse) -> Single<NabuSessionTokenResponse> {
        userRestored(error: error)
            .flatMap(weak: self) { (self, userRestored) -> Single<NabuSessionTokenResponse> in
                guard userRestored else {
                    return Single.error(error)
                }
                return self.recoverUserAndContinue(offlineToken: offlineToken)
            }
    }
    
    private func userRestored(error: Error) -> Single<Bool> {
        guard let error = NabuAPIError(error: error) else {
            return .just(false)
        }
        return .just(error == .alreadyRegistered)
    }
    
    private func recoverUserAndContinue(offlineToken: NabuOfflineTokenResponse) -> Single<NabuSessionTokenResponse> {
        jwtService.token
            .flatMapCompletable(weak: self) { (self, jwt) -> Completable in
                self.authenticationClient.recoverUser(offlineToken: offlineToken, jwt: jwt)
            }
            .andThen(refreshToken(offlineToken: offlineToken))
    }
    
    // MARK: - User Creation
    
    private func createUserIfNeeded() -> Single<NabuOfflineTokenResponse> {
        credentialsRepository.offlineTokenResponse
            .catchError(weak: self) { (self, error) in
                switch error {
                case MissingCredentialsError.offlineToken, MissingCredentialsError.userId:
                    return self.createUser()
                default:
                    throw error
                }
            }
    }
    
    private func createUser() -> Single<NabuOfflineTokenResponse> {
        jwtService.token
            .flatMap(weak: self) { (self, jwtToken) in
                self.userCreationClient.createUser(for: jwtToken)
            }
            .flatMap(weak: self) { (self, offlineTokenResponse) in
                self.credentialsRepository
                    .set(offlineTokenResponse: offlineTokenResponse)
                    .andThen(Single.just(offlineTokenResponse))
            }
    }
}
