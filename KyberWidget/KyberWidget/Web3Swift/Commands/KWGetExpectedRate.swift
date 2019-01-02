//
//  KWGetExpectedRate.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import TrustKeystore
import BigInt
import TrustCore

struct KWGetExpectedRateEncode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":true,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"srcQty\",\"type\":\"uint256\"}],\"name\":\"getExpectedRate\",\"outputs\":[{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let source: Address
  let dest: Address
  let amount: BigInt

  var command: String {
    let official = amount | BigInt(2).power(255) // using official Kyber's reserve
    return "web3.eth.abi.encodeFunctionCall(\(KWGetExpectedRateEncode.abi), [\"\(source.description)\", \"\(dest.description)\", \"\(official.hexEncoded)\"])"
  }
}

struct KWGetExpectedRateDecode: KWWeb3Request {
  typealias Response = [String: String]

  let data: String

  var command: String {
    return "web3.eth.abi.decodeParameters([{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}], '\(data)')"
  }
}
