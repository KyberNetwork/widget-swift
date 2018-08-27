//
//  KWGetTokenBalance.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import TrustCore

struct KWGetTokenBalanceEncode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"}],\"name\":\"balanceOf\",\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let address: Address

  var command: String {
    return "web3.eth.abi.encodeFunctionCall(\(KWGetTokenBalanceEncode.abi), [\"\(address.description)\"])"
  }
}

struct KWGetTokenBalanceDecode: KWWeb3Request {
  typealias Response = String

  let data: String

  var command: String {
    return "web3.eth.abi.decodeParameter('uint', '\(data)')"
  }
}
