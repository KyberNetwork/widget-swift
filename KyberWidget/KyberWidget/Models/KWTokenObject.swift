//
//  TokenObject.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import TrustCore
import TrustKeystore

// name + symbol to display
// icon if not set it will use local icon saved under symbol.lowercased() name
// for example: ETH, its icon name is eth
public struct KWTokenObject {

  let name: String
  let symbol: String
  let address: String
  let icon: String
  let decimals: Int

  public init(
    name: String,
    symbol: String,
    address: String,
    decimals: Int
    ) {
    self.name = name
    self.symbol = symbol
    self.address = address
    self.icon = symbol.lowercased()
    self.decimals = decimals
  }

  public init(localDict: JSONDictionary) {
    self.name = localDict["name"] as? String ?? ""
    let symbol = localDict["symbol"] as? String ?? ""
    self.symbol = symbol
    self.icon = localDict["icon"] as? String ?? symbol.lowercased()
    self.address = (localDict["address"] as? String ?? "").lowercased()
    self.decimals = localDict["decimal"] as? Int ?? 0
  }

  // init from tracker api
  public init(trackerDict: JSONDictionary) {
    self.name = trackerDict["name"] as? String ?? ""
    let symbol = trackerDict["symbol"] as? String ?? ""
    self.symbol = symbol
    self.icon = symbol.lowercased()
    self.address = (trackerDict["address"] as? String ?? "").lowercased()
    self.decimals = trackerDict["decimals"] as? Int ?? 0
  }

  static public func token(with symbol: String, env: KWEnvironment) -> KWTokenObject? {
    let tokens = KWJSONLoadUtil.loadListSupportedTokensFromJSONFile(env: env)
    return tokens.first(where: { $0.symbol.uppercased() == symbol.uppercased() })
  }

  static public func ethToken(env: KWEnvironment) -> KWTokenObject {
    return self.token(with: "ETH", env: env)!
  }

  var iconURL: String {
    // Token icons from Kyber public repo
    let url = "https://raw.githubusercontent.com/KyberNetwork/KyberNetwork.github.io/master/DesignAssets/tokens/iOS/\(self.symbol.lowercased()).png"
    return url
  }

  var isETH: Bool { return symbol == "ETH" }
  var isKNC: Bool { return symbol == "KNC" }
  var isDGX: Bool { return symbol == "DGX" }
  var isDAI: Bool { return symbol == "DAI" }
  var isMKR: Bool { return symbol == "MKR" }
  var isPRO: Bool { return symbol == "PRO" }
  var isPT: Bool { return symbol == "PT" }
  var isTUSD: Bool { return symbol == "TUSD" && name.lowercased() == "trueusd" }


  static public func ==(left: KWTokenObject, right: KWTokenObject) -> Bool {
    return left.address == right.address
  }

  static public func !=(left: KWTokenObject, right: KWTokenObject) -> Bool {
    return !(left == right)
  }
}
