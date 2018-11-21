//
//  KWExchangeRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import BigInt
import TrustKeystore
import TrustCore

struct KWExchangeRequestEncode: KWWeb3Request {
  typealias Response = String

  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"name\":\"dest\",\"type\":\"address\"}, {\"name\":\"destAddress\",\"type\":\"address\"},{\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"name\":\"walletId\",\"type\":\"address\"}],\"name\":\"trade\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let exchange: KWTransaction
  let address: String

  var command: String {
    let minRate: BigInt = {
      guard let minRate = exchange.minRate else { return BigInt(0) }
      return minRate * BigInt(10).power(18 - exchange.to.decimals)
    }()
    let walletID = self.exchange.commissionID ?? "0x0000000000000000000000000000000000000000"
    let amountTo: String = (exchange.amountTo ?? BigInt(2).power(255)).description
    let command = "web3.eth.abi.encodeFunctionCall(\(KWExchangeRequestEncode.abi), [\"\(exchange.from.address.description)\", \"\(exchange.amountFrom.description)\", \"\(exchange.to.address.description)\", \"\(address)\", \"\(amountTo)\", \"\(minRate.description)\", \"\(walletID)\"])"
    return command
  }
}

struct KWExchangeEventDataDecode: KWWeb3Request {
  typealias Response = [String: String]

  let data: String

  var command: String {
    return "web3.eth.abi.decodeParameters([{\"name\": \"src\", \"type\": \"address\"}, {\"name\": \"dest\", \"type\": \"address\"}, {\"name\": \"srcAmount\", \"type\": \"uint256\"}, {\"name\": \"destAmount\", \"type\": \"uint256\"}], \"\(data)\")"
  }
}
