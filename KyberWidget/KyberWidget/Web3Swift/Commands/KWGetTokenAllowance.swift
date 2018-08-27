//
//  KWGetTokenAllowance.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt
import TrustKeystore
import TrustCore

struct KWGetTokenAllowanceEndcode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"},{\"name\":\"_spender\",\"type\":\"address\"}],\"name\":\"allowance\",\"outputs\":[{\"name\":\"o_remaining\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"

  let ownerAddress: Address
  let spenderAddress: Address

  var command: String {
    return "web3.eth.abi.encodeFunctionCall(\(KWGetTokenAllowanceEndcode.abi), [\"\(ownerAddress.description)\", \"\(spenderAddress.description)\"])"
  }
}

struct KWGetTokenAllowanceDecode: KWWeb3Request {
  typealias Response = String

  let data: String

  var command: String {
    return "web3.eth.abi.decodeParameter('uint', '\(data)')"
  }
}
