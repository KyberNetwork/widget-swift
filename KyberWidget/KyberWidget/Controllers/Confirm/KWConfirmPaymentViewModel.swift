//
//  KWConfirmPaymentViewModel.swift
//  KyberPayiOS
//
//  Created by Manh Le on 22/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt
import TrustCore
import TrustKeystore

public class KWConfirmPaymentViewModel: NSObject {

  let dataType: KWDataType
  let payment: KWPayment
  var gasLimit: BigInt?
  let provider: KWExternalProvider
  let keystore: KWKeystore

  init(
    dataType: KWDataType,
    payment: KWPayment,
    network: KWEnvironment,
    keystore: KWKeystore
    ) {
    self.dataType = dataType
    self.payment = payment
    self.gasLimit = payment.gasLimit
    self.keystore = keystore
    self.provider = KWExternalProvider(keystore: keystore, network: network)
  }

  var newPayment: KWPayment {
    return KWPayment(
      from: self.payment.from,
      to: self.payment.to,
      account: self.payment.account,
      destWallet: self.payment.destWallet,
      amountFrom: self.payment.amountFrom,
      amountTo: self.payment.amountTo,
      minRate: self.payment.minRate,
      gasPrice: self.payment.gasPrice,
      gasLimit: self.gasLimit,
      expectedRate: self.payment.expectedRate,
      chainID: self.payment.chainID,
      commissionID: self.payment.commissionID
    )
  }

  var isPaymentDataViewHidden: Bool {
    return self.dataType != .pay && self.dataType != .buy
  }

  var paymentOrBuyDestTextString: String {
    switch self.dataType {
    case .pay:
      return "\(KWStringConfig.current.addressToPay): "
    case .buy:
      return "\(KWStringConfig.current.youAreAboutToPay): "
    default:
      return ""
    }
  }

  var paymentOrBuyDestValueString: String {
    switch self.dataType {
    case .pay:
      return "\(self.payment.destWallet.prefix(16))...\(self.payment.destWallet.suffix(5))"
    case .buy:
      return self.paymentFromAmountString
    default:
      return ""
    }
  }

  var buyAmountReceiveString: String {
    guard let expectedReceive = self.estimatedReceivedAmountBigInt else { return "" }
    let string = expectedReceive.string(
      decimals: self.payment.to.decimals,
      maxFractionDigits: max(9, self.payment.to.decimals)
    )
    return "\(string.prefix(12)) \(self.payment.to.symbol)"
  }

  var paymentFromAmountString: String {
    let amountFrom: BigInt = self.payment.expectedFromAmount(dataType: self.dataType)
    let string = amountFrom.string(
      decimals: self.payment.from.decimals,
      maxFractionDigits: min(6, self.payment.from.decimals)
    )
    return "\(string.prefix(12)) \(self.payment.from.symbol)"
  }

  var estimatedReceivedAmountBigInt: BigInt? {
    if self.payment.amountTo != nil { return self.payment.amountTo }
    if self.payment.from == self.payment.to { return self.payment.amountFrom }
    guard let rate = self.payment.expectedRate else { return nil }
    return rate * self.payment.amountFrom / BigInt(10).power(self.payment.from.decimals)
  }

  var paymentEstimatedReceivedAmountString: String {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "~ --- \(self.payment.to.symbol)" }
    let string = estReceived.string(
      decimals: self.payment.to.decimals,
      maxFractionDigits: min(6, self.payment.to.decimals)
    )
    return "~ \(string.prefix(12)) \(self.payment.to.symbol)"
  }

  var isSwapDataViewHidden: Bool { return self.dataType != .swap }
  var swapFromAmountString: String { return self.paymentFromAmountString }
  var swapToAmountString: String {
    let valueString: String = {
      guard let receivedAmount = self.estimatedReceivedAmountBigInt else { return "0" }
      let string = receivedAmount.string(
        decimals: self.payment.to.decimals,
        maxFractionDigits: max(self.payment.to.decimals, 9)
      )
      return "\(string.prefix(12))"
    }()
    return "\(valueString) \(self.payment.to.symbol)"
  }
  var swapExpectedRateString: String {
    let rateString: String = {
      guard let rate = self.payment.expectedRate else { return "0" }
      let string = rate.string(
        decimals: self.payment.to.decimals,
        maxFractionDigits: max(self.payment.to.decimals, 9)
      )
      return "\(string.prefix(12))"
    }()
    return "1 \(self.payment.from.symbol) ~ \(rateString) \(self.payment.to.symbol)"
  }

  // A/B: want to hide min rate here
  var isMinRateHidden: Bool {  return self.payment.from == self.payment.to }
  var displayMinRate: String {
    guard let minRate = self.payment.minRate else { return "--" }
    return minRate.string(
      decimals: self.payment.to.decimals,
      maxFractionDigits: min(6, self.payment.to.decimals)
    )
  }

  var displayGasPrice: String {
    return self.payment.gasPrice?.string(units: .gwei, maxFractionDigits: 2) ?? "-"
  }

  var displayTransactionFeeETH: String {
    guard let gasPrice = self.payment.gasPrice, let gasLimit = self.gasLimit else {
      return "~ --"
    }
    let fee: BigInt = gasPrice * gasLimit
    let feeString: String = fee.string(units: .ether, maxFractionDigits: 6)
    return "~ \(feeString.prefix(12)) ETH"
  }

  func getEstimatedGasLimit(completion: @escaping () -> Void) {
    if self.payment.from == self.payment.to {
      print("Estimated gas for transfer token")
      self.provider.getTransferEstimateGasLimit(for: self.payment) { result in
        if case .success(let gasLimit) = result {
          self.gasLimit = gasLimit
          print("Success loading est gas limit")
        } else if case .failure(let error) = result {
          print("Error loading est gas limit with error: \(error.description)")
        } else {
          print("Unknown result est gas limit")
        }
        completion()
      }
    } else {
      print("Estimated gas for exchange token")
      self.provider.getSwapEstimateGasLimit(for: self.payment) { result in
        if case .success(let gasLimit) = result {
          self.gasLimit = gasLimit
          print("Success loading est gas limit")
        } else if case .failure(let error) = result {
          print("Error loading est gas limit with error: \(error.description)")
        } else {
          print("Unknown result est gas limit")
        }
        completion()
      }
    }
  }
}
