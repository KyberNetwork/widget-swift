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
  let transaction: KWTransaction
  var gasLimit: BigInt?
  let provider: KWExternalProvider
  let keystore: KWKeystore

  init(
    dataType: KWDataType,
    transaction: KWTransaction,
    network: KWEnvironment,
    keystore: KWKeystore
    ) {
    self.dataType = dataType
    self.transaction = transaction
    self.gasLimit = transaction.gasLimit
    self.keystore = keystore
    self.provider = KWExternalProvider(keystore: keystore, network: network)
  }

  var newTransaction: KWTransaction {
    return KWTransaction(
      from: self.transaction.from,
      to: self.transaction.to,
      account: self.transaction.account,
      destWallet: self.transaction.destWallet,
      amountFrom: self.transaction.amountFrom,
      amountTo: self.transaction.amountTo,
      minRate: self.transaction.minRate,
      gasPrice: self.transaction.gasPrice,
      gasLimit: self.gasLimit,
      expectedRate: self.transaction.expectedRate,
      chainID: self.transaction.chainID,
      commissionID: self.transaction.commissionID
    )
  }

  // Payment and Buy Widgets data as they are quite similar UIs
  var isPaymentDataViewHidden: Bool {
    return self.dataType != .pay && self.dataType != .buy
  }

  // YOU ARE ABOUT TO PAY or Address to pay
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

  // Pay Widget: show address to pay
  // Buy Widget: Show estimated amount to pay
  var paymentOrBuyDestValueString: String {
    switch self.dataType {
    case .pay:
      return "\(self.transaction.destWallet.prefix(16))...\(self.transaction.destWallet.suffix(5))"
    case .buy:
      return self.paymentFromAmountString
    default:
      return ""
    }
  }

  // For Buy Widget only: Estimated amount receive
  var buyAmountReceiveString: String {
    guard let expectedReceive = self.estimatedReceivedAmountBigInt else { return "" }
    let string = expectedReceive.string(
      decimals: self.transaction.to.decimals,
      maxFractionDigits: max(9, self.transaction.to.decimals)
    )
    return "\(string.prefix(12)) \(self.transaction.to.symbol)"
  }

  // For Pay Widget only: Estimated amount to pay
  var paymentFromAmountString: String {
    let amountFrom: BigInt = self.transaction.expectedFromAmount(dataType: self.dataType)
    let string = amountFrom.string(
      decimals: self.transaction.from.decimals,
      maxFractionDigits: min(6, self.transaction.from.decimals)
    )
    return "\(string.prefix(12)) \(self.transaction.from.symbol)"
  }

  // Estimated receive amount for all widgets
  var estimatedReceivedAmountBigInt: BigInt? {
    if self.transaction.amountTo != nil { return self.transaction.amountTo }
    if self.transaction.from == self.transaction.to { return self.transaction.amountFrom }
    guard let rate = self.transaction.expectedRate else { return nil }
    return rate * self.transaction.amountFrom / BigInt(10).power(self.transaction.from.decimals)
  }

  var paymentEstimatedReceivedAmountString: String {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "~ --- \(self.transaction.to.symbol)" }
    let string = estReceived.string(
      decimals: self.transaction.to.decimals,
      maxFractionDigits: min(6, self.transaction.to.decimals)
    )
    return "~ \(string.prefix(12)) \(self.transaction.to.symbol)"
  }

  var isPaymentEstimatedReceivedAmountHidden: Bool {
    return !(self.dataType == .pay) || self.transaction.from == self.transaction.to
  }

  // Swap Widget confirm UIss
  var isSwapDataViewHidden: Bool { return self.dataType != .swap }
  var swapFromAmountString: String { return self.paymentFromAmountString }
  var swapToAmountString: String {
    let valueString: String = {
      guard let receivedAmount = self.estimatedReceivedAmountBigInt else { return "0" }
      let string = receivedAmount.string(
        decimals: self.transaction.to.decimals,
        maxFractionDigits: max(self.transaction.to.decimals, 9)
      )
      return "\(string.prefix(12))"
    }()
    return "\(valueString) \(self.transaction.to.symbol)"
  }

  var swapExpectedRateString: String {
    let rateString: String = {
      guard let rate = self.transaction.expectedRate else { return "0" }
      let string = rate.string(
        decimals: self.transaction.to.decimals,
        maxFractionDigits: max(self.transaction.to.decimals, 9)
      )
      return "\(string.prefix(12))"
    }()
    return "1 \(self.transaction.from.symbol) ~ \(rateString) \(self.transaction.to.symbol)"
  }

  // A/B: want to hide min rate here
  var isMinRateHidden: Bool {  return self.transaction.from == self.transaction.to }
  var displayMinRate: String {
    guard let minRate = self.transaction.minRate else { return "--" }
    return minRate.string(
      decimals: self.transaction.to.decimals,
      maxFractionDigits: min(6, self.transaction.to.decimals)
    )
  }

  var displayGasPrice: String {
    return self.transaction.gasPrice?.string(units: .gwei, maxFractionDigits: 2) ?? "-"
  }

  var displayTransactionFeeETH: String {
    guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.gasLimit else {
      return "~ --"
    }
    let fee: BigInt = gasPrice * gasLimit
    let feeString: String = fee.string(units: .ether, maxFractionDigits: 6)
    return "~ \(feeString.prefix(12)) ETH"
  }

  // MARK: Now we have all valid data to get the best estimated gas limit
  func getEstimatedGasLimit(completion: @escaping () -> Void) {
    if self.transaction.from == self.transaction.to {
      print("Estimated gas for transfer token")
      self.provider.getTransferEstimateGasLimit(for: self.transaction) { result in
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
      self.provider.getSwapEstimateGasLimit(for: self.transaction) { result in
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
