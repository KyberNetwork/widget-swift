//
//  KWTokenTransfer.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation

struct KWTokenTransferEncode: KWWeb3Request {
  typealias Response = String

  let amount: String
  let address: String

  static let abi = "{\"constant\": false, \"inputs\": [ { \"name\": \"_to\", \"type\": \"address\" }, { \"name\": \"_value\", \"type\": \"uint256\" } ], \"name\": \"transfer\", \"outputs\": [ { \"name\": \"success\", \"type\": \"bool\" } ], \"type\": \"function\"}"

  var command: String {
    return "web3.eth.abi.encodeFunctionCall(\(KWTokenTransferEncode.abi), [\"\(self.address)\", \"\(self.amount)\"])"
  }
}
