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
  let productName: String?
  let productAvatarURL: String?
  var productAvatarImage: UIImage?
  var gasLimit: BigInt
  let provider: KWExternalProvider
  let keystore: KWKeystore
  var isNeedsToSendApprove: Bool = true

  // advanced settings
  var gasPrice: BigInt = KWGasCoordinator.shared.mediumGas
  var gasPriceType = KWGasPriceType.medium

  var expectedRate: BigInt
  var minRate: BigInt
  var minRatePercent: Double = 3.0

  let walletType: String
  var balance: BigInt = BigInt(0)

  /*
   Amount, Address & Product Name have same attributed text format
   */
  fileprivate let dataNameAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
    NSAttributedString.Key.foregroundColor: UIColor.Kyber.segment,
  ]
  
  fileprivate let dataValueAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
    NSAttributedString.Key.foregroundColor: UIColor(red: 102, green: 102, blue: 102),
  ]

  init(
    dataType: KWDataType,
    transaction: KWTransaction,
    productName: String? = nil,
    productAvatarURL: String? = nil,
    productAvatarImage: UIImage? = nil,
    balance: BigInt,
    walletType: String,
    network: KWEnvironment,
    keystore: KWKeystore
    ) {
    self.dataType = dataType
    self.transaction = transaction
    self.keystore = keystore
    self.provider = KWExternalProvider(keystore: keystore, network: network)
    if self.transaction.from.isETH { self.isNeedsToSendApprove = false }

    self.expectedRate = self.transaction.expectedRate ?? BigInt(0)
    self.minRatePercent = 3.0
    self.minRate = BigInt(97.0) * self.expectedRate / BigInt(100.0)

    self.productName = productName
    self.productAvatarURL = productAvatarURL
    self.productAvatarImage = productAvatarImage
    self.balance = balance
    self.walletType = walletType
    self.gasLimit = KWGasConfiguration.calculateGasLimit(
      from: transaction.from,
      to: transaction.to,
      isPay: dataType == .pay
    )
  }

  var newTransaction: KWTransaction {
    return KWTransaction(
      from: self.transaction.from,
      to: self.transaction.to,
      account: self.transaction.account,
      destWallet: self.transaction.destWallet,
      amountFrom: self.amountFrom,
      amountTo: self.transaction.amountTo,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: self.gasLimit,
      expectedRate: self.expectedRate,
      chainID: self.transaction.chainID,
      commissionID: self.transaction.commissionID
    )
  }

  // Estimated receive amount for all widgets
  var estimatedReceivedAmountBigInt: BigInt {
    if let amountTo = self.transaction.amountTo { return amountTo }
    if self.transaction.from == self.transaction.to { return self.amountFrom }
    return self.expectedRate * self.amountFrom / BigInt(10).power(self.transaction.from.decimals)
  }

  var displayTransactionFeeETH: String {
    let realGasLimit: BigInt = self.isNeedsToSendApprove ? self.gasLimit + KWGasConfiguration.approveTokenGasLimitDefault : self.gasLimit
    let fee: BigInt = self.gasPrice * realGasLimit
    let feeString: String = fee.string(units: .ether, maxFractionDigits: 6)
    return "\(feeString.prefix(12)) ETH"
  }

  var amountFrom: BigInt {
    guard let amountTo = self.transaction.amountTo else { return self.transaction.amountFrom }
    return amountTo * BigInt(10).power(self.transaction.from.decimals) / self.expectedRate
  }

  var amountToSend: BigInt {
    guard let amountTo = self.transaction.amountTo, self.transaction.from != self.transaction.to else { return self.transaction.amountFrom }
    if self.minRate.isZero { return max(self.transaction.amountFrom, self.balance) }
    return amountTo * BigInt(10).power(self.transaction.from.decimals) / self.minRate
  }

  var isOrderDetailsDataHidden: Bool { return self.dataType != .pay }
  var orderProductName: String? { return self.productName }
  var orderProductAvatar: UIImage? { return self.productAvatarImage }
  var orderReceiveAmount: String {
    let string = self.estimatedReceivedAmountBigInt.string(
      decimals: self.transaction.to.decimals,
      maxFractionDigits: max(9, self.transaction.to.decimals)
    )
    return "\(string.prefix(12)) \(self.transaction.to.symbol)"
  }
  var orderDestAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.address): ", attributes: self.dataNameAttributes))
    attributedString.append(NSAttributedString(string: "\(self.transaction.destWallet.prefix(14))...\(self.transaction.destWallet.suffix(5))", attributes: self.dataValueAttributes))
    return attributedString
  }
  var orderTransactionFeeString: String {
    return self.displayTransactionFeeETH
  }

  var isTransactionDetailsDataHidden: Bool { return self.dataType == .pay }
  var transactionFromAmountString: String {
    let string = self.amountFrom.string(
      decimals: self.transaction.from.decimals,
      maxFractionDigits: max(self.transaction.from.decimals, 9)
    )
    return "\(string.prefix(12)) \(self.transaction.from.symbol)"
  }
  var transactionToAmountString: String {
    let string = self.estimatedReceivedAmountBigInt.string(
      decimals: self.transaction.to.decimals,
      maxFractionDigits: max(9, self.transaction.to.decimals)
    )
    return "\(string.prefix(12)) \(self.transaction.to.symbol)"
  }
  var transactionFeeString: String {
    return self.displayTransactionFeeETH
  }

  var transactionTypeText: String {
    switch self.dataType {
    case .pay: return KWStringConfig.current.youAreAboutToPay
    case .buy: return KWStringConfig.current.youAreAboutToBuy
    case .swap: return KWStringConfig.current.youAreAboutToSwap
    }
  }

  var firstAmountText: String {
    switch self.dataType {
    case .pay, .swap: return self.transactionFromAmountString
    case .buy: return self.transactionToAmountString
    }
  }

  var secondAmountAttributedString: NSAttributedString {
    if case .pay = self.dataType { return NSAttributedString() }
    let attributedString = NSMutableAttributedString()
    let text: String = {
      if case .swap = self.dataType { return KWStringConfig.current.to.lowercased() }
      return KWStringConfig.current.from.lowercased()
    }()
    let amount: String = {
      if case .swap = self.dataType { return self.transactionToAmountString }
      return self.transactionFromAmountString
    }()
    let normalAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium)
    ]
    let highlightAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .medium)
    ]
    attributedString.append(NSAttributedString(string: "\(text) ", attributes: normalAttributes))
    attributedString.append(NSAttributedString(string: amount, attributes: highlightAttributes))
    return attributedString
  }

  // private key, seeds, json
  var yourWalletType: String { return self.walletType }
  var yourWalletAddress: String {
    let address = self.transaction.account?.address.description ?? ""
    return "\(address.prefix(16))...\(address.suffix(5))"
  }

  var isBalanceEnoughAmountFrom: Bool {
    return self.balance >= self.amountFrom
  }

  var isBalanceForPayTransaction: Bool {
    guard let amountTo = self.transaction.amountTo else { return self.isBalanceEnoughAmountFrom }
    let amountFrom: BigInt = {
      if self.transaction.from == self.transaction.to { return self.amountFrom }
      if self.minRate.isZero { return max(self.transaction.amountFrom, self.balance) }
      return amountTo * BigInt(10).power(self.transaction.from.decimals) / self.minRate
    }()
    return self.balance >= amountFrom
  }

  var isMinRateValid: Bool {
    if self.dataType != .pay { return true }
    return !self.minRate.isZero
  }

  var isBalanceEnoughForTxFee: Bool {
    guard self.transaction.from.isETH else {
      return true
    }
    let totalAmountAndFee = self.amountToSend + self.gasPrice * self.gasLimit
    return totalAmountAndFee <= self.balance
  }

  func checkNeedToSendApproveToken(completion: @escaping () -> Void) {
    guard let address = self.transaction.account?.address else {
      self.isNeedsToSendApprove = true
      completion()
      return
    }
    self.provider.getAllowance(
      token: self.transaction.from,
      address: address,
      isPay: self.dataType == .pay) { result in
        switch result {
        case .success(let value):
          self.isNeedsToSendApprove = value < self.amountFrom
        case .failure:
          self.isNeedsToSendApprove = true
        }
        completion()
    }
  }

  func updateGasPriceType(_ type: KWGasPriceType) {
    self.gasPriceType = type
    switch type {
    case .slow: self.gasPrice = KWGasConfiguration.gasPriceSlow
    case .medium: self.gasPrice = KWGasConfiguration.gasPriceMedium
    case .fast: self.gasPrice = KWGasConfiguration.gasPriceFast
    default: break
    }
  }

  func updateMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
    self.minRate = BigInt(100.0 - percent) * self.expectedRate / BigInt(100)
    print("Selected min rate percent: \(percent)")
    print("Min rate value: \(self.minRate.string(decimals: self.transaction.to.decimals, maxFractionDigits: 6))")
  }

  // MARK: Now we have all val id data to get the best estimated gas limit
  func getEstimatedGasLimit(completion: @escaping () -> Void) {
    if self.dataType == .pay {
      print("Estimated gas for pay transaction")
      let transaction = self.transaction
      self.provider.getPayEstimateGasLimit(for: transaction) { result in
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
      return
    }
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

  // MARK: Getting data from node
  func getExpectedRateRequest(completion: @escaping () -> Void) {
    if self.transaction.from == self.transaction.to {
      if let rate = "1".toBigInt(decimals: self.transaction.from.decimals) {
        self.expectedRate = rate
        self.minRate = rate * BigInt(100.0 - self.minRatePercent) / BigInt(100)
      }
      print("Same tokens")
      completion()
      return
    }
    let from = self.transaction.from
    let to = self.transaction.to
    let amount = self.amountFrom
    print("Get expected rate for token")
    self.provider.getExpectedRate(from: from, to: to, amount: amount) { result in
      if case .success(let data) = result {
        self.expectedRate = data.0
        self.minRate = data.0 * BigInt(100.0 - self.minRatePercent) / BigInt(100)
        print("Success loading expected rate with \(data.0.fullString(decimals: to.decimals))")
      } else if case .failure(let error) = result {
        print("Error loading expected rate with error: \(error.description)")
      }
      completion()
    }
  }

  func getProductAvatarIfNeeded(completion: @escaping (Bool) -> Void) {
    guard let urlString = self.productAvatarURL, let url = URL(string: urlString), self.productAvatarImage == nil else {
      completion(false)
      return
    }
    DispatchQueue.global(qos: .background).async {
      URLSession.shared.dataTask(with: url) { (data, _, error) in
        DispatchQueue.main.async {
          if let data = data, error == nil, let image = UIImage(data: data) {
            self.productAvatarImage = image.resizeImage(toWidth: UIScreen.main.bounds.width - 44.0)
            completion(true)
          } else {
            completion(false)
          }
        }
        }.resume()
    }
  }

  func getBalance(completion: @escaping () -> Void) {
    print("Getting balance for \(self.transaction.from.symbol)")
    guard let address = self.transaction.account?.address else {
      print("Address is nil")
      completion()
      return
    }
    if self.transaction.from.isETH {
      self.provider.getETHBalance(address: address.description) { result in
        print("Done getting ETH balance")
        switch result {
        case .success(let bal):
          print("Getting ETH balance susccess")
          self.balance = bal
        case .failure(let error):
          print("Getting ETH balance failed error: \(error.localizedDescription)")
        }
        completion()
      }
    } else {
      self.provider.getTokenBalance(
        for: Address(string: self.transaction.from.address)!,
        address: address) { result in
          print("Done getting \(self.transaction.from.symbol) balance")
          switch result {
          case .success(let bal):
            print("Getting \(self.transaction.from.symbol) balance susccess")
            self.balance = bal
          case .failure(let error):
            print("Getting \(self.transaction.from.symbol) balance failed error: \(error.localizedDescription)")
          }
          completion()
      }
    }
  }
}
