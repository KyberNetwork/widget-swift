//
//  KWEnvironment.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

public enum KWEnvironment: Int {

  case mainnetTest = 0
  case production = 1
  case staging = 2
  case ropsten = 3
  case kovan = 4

  var displayName: String {
    switch self {
    case .mainnetTest: return "Mainnet"
    case .production: return "Production"
    case .staging: return "Staging"
    case .ropsten: return "Ropsten"
    case .kovan: return "Kovan"
    }
  }

  static let allEnvs: [KWEnvironment] = [
    KWEnvironment.mainnetTest,
    KWEnvironment.production,
    KWEnvironment.staging,
    KWEnvironment.ropsten,
    KWEnvironment.kovan,
  ]

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.customRPC?.etherScanEndpoint ?? ""
  }

  var customRPC: KPCustomRPC? {
    guard let json = KWJSONLoadUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KPCustomRPC(dictionary: json)
  }

  var endpoint: String { return self.customRPC?.endpoint ?? "" }

  var configFileName: String {
    switch self {
    case .mainnetTest: return "config_env_mainnet_test"
    case .production: return "config_env_production"
    case .staging: return "config_env_staging"
    case .ropsten: return "config_env_ropsten"
    case .kovan: return "config_env_kovan"
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .mainnetTest: return "http://api.etherscan.io/"
    case .production: return "http://api.etherscan.io/"
    case .staging: return "http://api-kovan.etherscan.io/"
    case .ropsten: return "http://api-ropsten.etherscan.io/"
    case .kovan: return "http://api-kovan.etherscan.io/"
    }
  }
}

public struct KPCustomRPC {
  let chainID: Int
  let chainName: String
  let endpoint: String

  let networkAddress: String
  let authorizedAddress: String
  let tokenIEOAddress: String
  let reserveAddress: String
  let etherScanEndpoint: String
  let tradeTopic: String

  public init(dictionary: JSONDictionary) {
    self.chainID = dictionary["networkId"] as? Int ?? 0
    self.chainName = dictionary["chainName"] as? String ?? ""
    self.endpoint = {
      var endpoint: String
      if let connections: JSONDictionary = dictionary["connections"] as? JSONDictionary,
        let https: [JSONDictionary] = connections["http"] as? [JSONDictionary] {
        let endpointJSON: JSONDictionary = https.count > 1 ? https[1] : https[0]
        endpoint = endpointJSON["endPoint"] as? String ?? ""
      } else {
        endpoint = dictionary["endpoint"] as? String ?? ""
      }
      return endpoint
    }()
    self.networkAddress = dictionary["network"] as? String ?? ""
    self.authorizedAddress = dictionary["authorize_contract"] as? String ?? ""
    self.tokenIEOAddress = dictionary["token_ieo"] as? String ?? ""
    self.reserveAddress = dictionary["reserve"] as? String ?? ""
    self.etherScanEndpoint = dictionary["ethScanUrl"] as? String ?? ""
    self.tradeTopic = dictionary["trade_topic"] as? String ?? ""
  }
}
