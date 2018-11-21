//
//  KWEnvironment.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

public enum KWEnvironment: Int {

  case mainnet = 0
  case production = 1
  case test = 2
  case ropsten = 3
  case rinkeby = 4

  var displayName: String {
    switch self {
    case .mainnet: return "Mainnet"
    case .production: return "Production"
    case .test: return "Test"
    case .ropsten: return "Ropsten"
    case .rinkeby: return "Rinkeby"
    }
  }

  static let allEnvs: [KWEnvironment] = [
    KWEnvironment.mainnet,
    KWEnvironment.production,
    KWEnvironment.test,
    KWEnvironment.ropsten,
    KWEnvironment.rinkeby,
  ]

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.customRPC?.etherScanEndpoint ?? ""
  }

  var customRPC: KWCustomRPC? {
    guard let json = KWJSONLoadUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KWCustomRPC(dictionary: json)
  }

  var endpoint: String { return self.customRPC?.endpoint ?? "" }

  var configFileName: String {
    switch self {
    case .mainnet: return "config_env_production"
    case .production: return "config_env_production"
    case .test: return "config_env_ropsten"
    case .ropsten: return "config_env_ropsten"
    case .rinkeby: return "config_env_rinkeby"
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .mainnet: return "http://api.etherscan.io/"
    case .production: return "http://api.etherscan.io/"
    case .test: return "http://api-ropsten.etherscan.io/"
    case .ropsten: return "http://api-ropsten.etherscan.io/"
    case .rinkeby: return "https://api-rinkeby.etherscan.io/"
    }
  }
}

public struct KWCustomRPC {
  let chainID: Int
  let chainName: String
  let endpoint: String

  let networkAddress: String
  let payAddress: String
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
    self.payAddress = dictionary["payWrapper"] as? String ?? ""
    self.authorizedAddress = dictionary["authorize_contract"] as? String ?? ""
    self.tokenIEOAddress = dictionary["token_ieo"] as? String ?? ""
    self.reserveAddress = dictionary["reserve"] as? String ?? ""
    self.etherScanEndpoint = dictionary["ethScanUrl"] as? String ?? ""
    self.tradeTopic = dictionary["trade_topic"] as? String ?? ""
  }
}
