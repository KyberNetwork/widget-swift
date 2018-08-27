//
//  KWNetworkProvider.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//


import Moya

enum KWNetworkProvider {
  case getMaxGasPrice// = "/getMaxGasPrice"
  case getGasPrice// = "/getGasPrice"
  case getSupportedTokens(env: KWEnvironment)// = "/api/tokens/supported"
}

extension KWNetworkProvider: TargetType {

  var baseURL: URL {
    switch self {
    case .getSupportedTokens(let env):
      let string = env == .ropsten ? "https://staging-tracker.knstats.com/api/tokens/supported" : "https://tracker.kyber.network/api/tokens/supported"
      return URL(string: string)!
    case .getMaxGasPrice, .getGasPrice:
      let baseURLString = "https://production-cache.kyber.network"
      return URL(string: baseURLString)!
    }
  }

  var path: String {
    switch self {
    case .getSupportedTokens:
      return ""
    case .getGasPrice:
      return "/getGasPrice"
    case .getMaxGasPrice:
      return "/getMaxGasPrice"
    }
  }

  var method: Moya.Method {
    return .get
  }

  var task: Task {
    return .requestPlain
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": "manhlx_kyberpayios",
    ]
  }
}
