//
//  KWPayRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 21/11/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import TrustKeystore
import BigInt
import TrustCore

struct KWPayRequestEncode: KWWeb3Request {
  typealias Response = String

  static var paymentData = ""

  static let abi = "{\"constant\":false,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"},{\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"destAddress\",\"type\":\"address\"},{\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"name\":\"walletId\",\"type\":\"address\"},{\"name\":\"paymentData\",\"type\":\"bytes\"},{\"name\":\"hint\",\"type\":\"bytes\"},{\"name\":\"kyberNetworkProxy\",\"type\":\"address\"}],\"name\":\"pay\",\"outputs\":[],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let pay: KWTransaction
  let kyberNetworkProxy: String

  var command: String {
    let src: String = pay.from.address.description
    let srcAmount: String = pay.amountFrom.description
    let dest: String = pay.to.address.description
    let destAddress: String = pay.destWallet
    let minConversionRate: BigInt = {
      guard let minRate = pay.minRate else { return BigInt(0) }
      return minRate * BigInt(10).power(18 - pay.to.decimals)
    }()
    let walletID = self.pay.commissionID ?? "0x0000000000000000000000000000000000000000"
    let paymentData: String = KWPayRequestEncode.paymentData.hexEncoded
    print("payment data: \(paymentData)")
    let hint: String = "PERM".hexEncoded
    let maxDestAmount: String = (pay.amountTo ?? BigInt(2).power(255)).description
    let command = "web3.eth.abi.encodeFunctionCall(\(KWPayRequestEncode.abi), [\"\(src)\", \"\(srcAmount)\", \"\(dest)\", \"\(destAddress)\", \"\(maxDestAmount)\", \"\(minConversionRate.description)\", \"\(walletID)\", \"\(paymentData)\", \"\(hint)\", \"\(kyberNetworkProxy)\"])"
    return command
  }
}
