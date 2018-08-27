//
//  KWSendApproveToken.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation

struct KWSendApproveTokenEncode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"_spender\",\"type\":\"address\"},{\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"approve\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"}"

  let address: String
  let value: String

  var command: String {
    return "web3.eth.abi.encodeFunctionCall(\(KWSendApproveTokenEncode.abi), [\"\(self.address)\", \"\(self.value)\"])"
  }
}
