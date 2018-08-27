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

  let payment: KWPayment
  var gasLimit: BigInt?
  let provider: KWExternalProvider
  let keystore: KWKeystore

  init(payment: KWPayment, network: KWEnvironment, keystore: KWKeystore) {
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

  var destAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let addressTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.segment,
      ]
    let addressValueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor(red: 102, green: 102, blue: 102),
      ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.addressToPay): ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: "\(self.payment.destWallet.prefix(14))...\(self.payment.destWallet.suffix(5))", attributes: addressValueAttributes))
    return attributedString
  }

  var displayFromAmount: String {
    let amountFrom: BigInt = {
      if self.payment.from == self.payment.to { return self.payment.amountFrom }
      if self.payment.amountTo == nil { return self.payment.amountFrom }
      // amountFrom is computed using min rate
      guard let minRate = self.payment.minRate, let expectedRate = self.payment.expectedRate, !expectedRate.isZero else {
        return BigInt(0)
      }
      return self.payment.amountFrom * minRate / expectedRate
    }()
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

  var displayEstimatedReceivedAmountBigInt: String {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "~ --- \(self.payment.to.symbol)" }
    let string = estReceived.string(
      decimals: self.payment.to.decimals,
      maxFractionDigits: min(6, self.payment.to.decimals)
    )
    return "~ \(string.prefix(12)) \(self.payment.to.symbol)"
  }

  // A/B: want to hide min rate here
  var isMinRateHidden: Bool { return true }//return self.payment.from == self.payment.to }
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
