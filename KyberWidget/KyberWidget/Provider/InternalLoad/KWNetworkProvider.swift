//
//  KWNetworkProvider.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//


import Moya

public enum KWNetworkProvider {
  case getMaxGasPrice// = "/getMaxGasPrice"
  case getGasPrice// = "/getGasPrice"
  case getSupportedTokens(env: KWEnvironment)// = "/api/tokens/supported"
  case getRates(env: KWEnvironment)
}

extension KWNetworkProvider: TargetType {

  public var baseURL: URL {
    switch self {
    case .getSupportedTokens:
      let string = "https://api.kyber.network/currencies"
      return URL(string: string)!
    case .getRates(let env):
      let string: String = {
        if env == .mainnet || env == .production { return "https://production-cache.kyber.network/getRate" }
        if env == .test || env == .ropsten { return "https://ropsten-cache.knstats.com/rate" }
        return "https://rinkeby-cache.knstats.com/rate"
      }()
      return URL(string: string)!
    case .getMaxGasPrice, .getGasPrice:
      let string = "https://production-cache.kyber.network"
      return URL(string: string)!
    }
  }

  public var path: String {
    switch self {
    case .getSupportedTokens, .getRates:
      return ""
    case .getGasPrice:
      return "/getGasPrice"
    case .getMaxGasPrice:
      return "/getMaxGasPrice"
    }
  }

  public var method: Moya.Method {
    return .get
  }

  public var task: Task {
    return .requestPlain
  }

  public var sampleData: Data {
    return Data() // sample data for UITest
  }

  public var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": "manhlx_kyberpayios",
    ]
  }
}
