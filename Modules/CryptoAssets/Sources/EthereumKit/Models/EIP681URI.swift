// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation
import MoneyKit
import PlatformKit
import ToolKit
import WalletCore

/// Implementation of EIP 681 URI
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-681.md
public struct EIP681URI {

    public enum Method: Equatable {
        case send(amount: CryptoValue?, gasLimit: BigUInt?, gasPrice: BigUInt?)
        case transfer(destination: String, amount: CryptoValue?)

        public var amount: CryptoValue? {
            switch self {
            case .send(let amount, _, _):
                return amount
            case .transfer(_, let amount):
                return amount
            }
        }

        public var destination: String? {
            switch self {
            case .send:
                return nil
            case .transfer(let destination, _):
                return destination
            }
        }
    }

    public let cryptoCurrency: CryptoCurrency
    public let address: String
    public let method: Method
    public var amount: CryptoValue? {
        method.amount
    }

    public init?(address: String, cryptoCurrency: CryptoCurrency) {
        guard Self.validate(address: address) else {
            return nil
        }
        if let erc20ContractAddress = cryptoCurrency.assetModel.kind.erc20ContractAddress {
            self.address = erc20ContractAddress
            method = .transfer(
                destination: address,
                amount: nil
            )
        } else if cryptoCurrency.isCoin, cryptoCurrency.assetModel.evmNetwork != nil {
            self.address = address
            method = .send(amount: nil, gasLimit: nil, gasPrice: nil)
        } else {
            return nil
        }
        self.cryptoCurrency = cryptoCurrency
    }

    public init?(
        url: String,
        network: EVMNetwork,
        enabledCurrenciesService: EnabledCurrenciesServiceAPI
    ) {
        guard let parser = EIP681URIParser(string: url) else {
            return nil
        }
        guard let cryptoCurrency = parser.cryptoCurrency(
            enabledCurrenciesService: enabledCurrenciesService,
            network: network
        ) else {
            return nil
        }
        guard let method = parser.method.method(cryptoCurrency: cryptoCurrency) else {
            return nil
        }
        guard Self.validate(address: parser.address) else {
            return nil
        }
        guard Self.validate(method: method) else {
            return nil
        }
        self.init(cryptoCurrency: cryptoCurrency, address: parser.address, method: method)
    }

    init(cryptoCurrency: CryptoCurrency, address: String, method: EIP681URI.Method) {
        self.cryptoCurrency = cryptoCurrency
        self.address = address
        self.method = method
    }

    static func validate(method: Method) -> Bool {
        switch method {
        case .send:
            return true
        case .transfer(let address, _):
            return validate(address: address)
        }
    }

    static func validate(address: String) -> Bool {
        WalletCore.CoinType.ethereum.validate(address: address)
    }
}

extension EIP681URIParser {

    /// From a EIP681URIParser, returns correct CryptoCurrency.
    func cryptoCurrency(
        enabledCurrenciesService: EnabledCurrenciesServiceAPI,
        network: EVMNetwork
    ) -> CryptoCurrency? {
        switch method {
        case .send:
            // If this is a 'send', then we are sending Ethereum.
            return network.cryptoCurrency
        case .transfer:
            // If this is a 'transfer', then we need to find which token we are sending.
            // We do this by matching 'address' with one of the coins contract address.
            return enabledCurrenciesService.allEnabledCryptoCurrencies
                .first { cryptoCurrency in
                    cryptoCurrency.assetModel.kind.erc20ContractAddress?
                        .caseInsensitiveCompare(address) == .orderedSame
                }
        }
    }
}

extension EIP681URIParser.Method {
    func method(cryptoCurrency: CryptoCurrency) -> EIP681URI.Method? {
        switch self {
        case .send(let amount, let gasLimit, let gasPrice):
            return .send(
                amount: amount
                    .flatMap(BigInt.init(scientificNotation:))
                    .flatMap { amount in
                        CryptoValue.create(minor: amount, currency: cryptoCurrency)
                    },
                gasLimit: gasLimit.flatMap { BigUInt($0) },
                gasPrice: gasPrice.flatMap { BigUInt($0) }
            )
        case .transfer(let address, let amount):
            guard let address = address else {
                return nil
            }
            return .transfer(
                destination: address,
                amount: amount
                    .flatMap(BigInt.init(scientificNotation:))
                    .flatMap { amount in
                        CryptoValue.create(minor: amount, currency: cryptoCurrency)
                    }
            )
        }
    }
}
