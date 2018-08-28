//
//  KWGetUserCapInWei.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import TrustKeystore
import TrustCore
import BigInt

struct KWGetUserCapInWeiEncode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"user\",\"type\":\"address\"}],\"name\":\"getUserCapInWei\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let address: Address

  var command: String {
    return "web3.eth.abi.encodeFunctionCall(\(KWGetUserCapInWeiEncode.abi), [\"\(address)\"])"
  }
}

struct KWGetUserCapInWeiDecode: KWWeb3Request {
  typealias Response = String

  let data: String

  var command: String {
    return "web3.eth.abi.decodeParameter('uint', '\(data)')"
  }
}
