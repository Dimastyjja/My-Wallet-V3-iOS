// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import WalletPayloadKit

public enum WalletInfoError: Error {
    case failToDecodeBase64Component
    case failToDecodeToWalletInfo(Error)
    case sessionTokenMismatch(originSession: String, base64Str: String)
    case missingSessionToken(originSession: String, base64Str: String)
}

public struct WalletInfo: Codable, Equatable {

    // MARK: - UserType

    public enum UserType: String, Codable {
        /// only wallet
        case wallet = "WALLET"

        /// only exchange
        case exchange = "EXCHANGE"

        /// wallet object has embedded exchange object
        case linked = "WALLET_EXCHANGE_LINKED"

        /// payload has only root-level wallet & exchange objects
        case notLinked = "WALLET_EXCHANGE_NOT_LINKED"

        /// there are root-level wallet & exchange objects, but wallet also has embedded exchange object (e.g. tied to different e-mail & linked via legacy linking)
        case both = "WALLET_EXCHANGE_BOTH"
    }

    // MARK: - Wallet

    public struct Wallet: Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case guid
            case email
            case twoFaType = "two_fa_type"
            case emailCode = "email_code"
            case isMobileSetup = "is_mobile_setup"
            case hasCloudBackup = "has_cloud_backup"
            case sessionId = "session_id"
            case nabu
        }

        public var guid: String
        public var email: String?
        public var twoFaType: WalletAuthenticatorType?
        public var emailCode: String?
        public var isMobileSetup: Bool?
        public var hasCloudBackup: Bool?
        public var sessionId: String?
        public var nabu: Nabu?

        public init(
            guid: String,
            email: String? = nil,
            twoFaType: WalletAuthenticatorType? = nil,
            emailCode: String? = nil,
            isMobileSetup: Bool? = nil,
            hasCloudBackup: Bool? = nil,
            sessionId: String? = nil,
            nabu: Nabu? = nil
        ) {
            self.guid = guid
            self.email = email
            self.twoFaType = twoFaType
            self.emailCode = emailCode
            self.isMobileSetup = isMobileSetup
            self.hasCloudBackup = hasCloudBackup
            self.sessionId = sessionId
            self.nabu = nabu
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guid = try container.decode(String.self, forKey: .guid)
            email = try container.decodeIfPresent(String.self, forKey: .email)
            twoFaType = try container.decodeIfPresent(WalletAuthenticatorType.self, forKey: .twoFaType)
            emailCode = try container.decodeIfPresent(String.self, forKey: .emailCode)
            isMobileSetup = try container.decodeIfPresent(Bool.self, forKey: .isMobileSetup)
            hasCloudBackup = try container.decodeIfPresent(Bool.self, forKey: .hasCloudBackup)
            sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
            nabu = try container.decodeIfPresent(Nabu.self, forKey: .nabu)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(guid, forKey: .guid)
            try container.encodeIfPresent(email, forKey: .email)
            try container.encodeIfPresent(twoFaType, forKey: .twoFaType)
            try container.encodeIfPresent(emailCode, forKey: .emailCode)
            try container.encodeIfPresent(isMobileSetup, forKey: .isMobileSetup)
            try container.encodeIfPresent(hasCloudBackup, forKey: .hasCloudBackup)
            try container.encodeIfPresent(sessionId, forKey: .sessionId)
            try container.encodeIfPresent(nabu, forKey: .nabu)
        }
    }

    // MARK: - Nabu

    public struct Nabu: Codable, Equatable {
        private enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case recoveryToken = "recovery_token"
            case recoverable
        }

        public var userId: String
        public var recoveryToken: String
        public var recoverable: Bool

        public init(
            userId: String,
            recoveryToken: String,
            recoverable: Bool
        ) {
            self.userId = userId
            self.recoveryToken = recoveryToken
            self.recoverable = recoverable
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            userId = try container.decode(String.self, forKey: .userId)
            recoveryToken = try container.decode(String.self, forKey: .recoveryToken)
            recoverable = try container.decode(Bool.self, forKey: .recoverable)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(userId, forKey: .userId)
            try container.encode(recoveryToken, forKey: .recoveryToken)
            try container.encode(recoverable, forKey: .recoverable)
        }
    }

    // MARK: - Exchange

    public struct Exchange: Codable, Equatable {
        enum CodingKeys: String, CodingKey {
            case twoFaMode = "two_fa_mode"
            case email
        }

        public var twoFaMode: Bool?
        public var email: String?

        public init(
            twoFaMode: Bool? = nil,
            email: String? = nil
        ) {
            self.twoFaMode = twoFaMode
            self.email = email
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            twoFaMode = try container.decodeIfPresent(Bool.self, forKey: .twoFaMode)
            email = try container.decodeIfPresent(String.self, forKey: .email)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(twoFaMode, forKey: .twoFaMode)
            try container.encodeIfPresent(email, forKey: .email)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case product
        case exchangeAuthUrl = "exchange_auth_url"
        case exchange
        case userType = "user_type"
        case unified
        case mergeable
        case upgradeable
        case wallet
    }

    public var sessionId: String?
    public var product: String?
    public var exchangeAuthUrl: String?
    public var exchange: Exchange?
    public var userType: UserType?
    public var unified: Bool?
    public var mergeable: Bool?
    public var upgradeable: Bool?
    public var wallet: Wallet?

    public static var empty: WalletInfo {
        self.init()
    }

    public init(
        sessionId: String? = nil,
        product: String? = nil,
        exchangeAuthUrl: String? = nil,
        exchange: Exchange? = nil,
        userType: UserType? = nil,
        unified: Bool? = nil,
        mergeable: Bool? = nil,
        upgradeable: Bool? = nil,
        wallet: Wallet? = nil
    ) {
        self.sessionId = sessionId
        self.product = product
        self.exchangeAuthUrl = exchangeAuthUrl
        self.exchange = exchange
        self.userType = userType
        self.unified = unified
        self.mergeable = mergeable
        self.upgradeable = upgradeable
        self.wallet = wallet
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        product = try container.decodeIfPresent(String.self, forKey: .product)
        exchangeAuthUrl = try container.decodeIfPresent(String.self, forKey: .exchangeAuthUrl)
        exchange = try container.decodeIfPresent(Exchange.self, forKey: .exchange)
        userType = try container.decodeIfPresent(UserType.self, forKey: .userType)
        unified = try container.decodeIfPresent(Bool.self, forKey: .unified)
        mergeable = try container.decodeIfPresent(Bool.self, forKey: .mergeable)
        upgradeable = try container.decodeIfPresent(Bool.self, forKey: .upgradeable)
        wallet = try container.decodeIfPresent(Wallet.self, forKey: .wallet)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encodeIfPresent(product, forKey: .product)
        try container.encodeIfPresent(exchangeAuthUrl, forKey: .exchangeAuthUrl)
        try container.encodeIfPresent(exchange, forKey: .exchange)
        try container.encodeIfPresent(userType, forKey: .userType)
        try container.encodeIfPresent(unified, forKey: .unified)
        try container.encodeIfPresent(mergeable, forKey: .mergeable)
        try container.encodeIfPresent(upgradeable, forKey: .upgradeable)
        try container.encodeIfPresent(wallet, forKey: .wallet)
    }
}

extension WalletInfo {

    /// Determine whether the account attached could be upgraded
    public var shouldUpgradeAccount: Bool {
        guard let unified = unified,
              let upgradeable = upgradeable,
              let mergeable = mergeable,
              userType != nil
        else {
            return false
        }
        return !unified && (upgradeable || mergeable)
    }
}
