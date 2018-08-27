//
//  KWPaymentMethodViewModel.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt
import TrustKeystore
import TrustCore

public enum KWGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case custom = 3
}

public class KWPaymentMethodViewModel: NSObject {
  let defaultTokenIconImg = UIImage(named: "default_token", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil)

  let receiverAddress: String
  let receiverToken: KWTokenObject
  let receiverTokenAmount: String?
  let network: KWEnvironment
  let dataType: KWDataType

  let signer: String?
  let commissionID: String?

  let keystore: KWKeystore
  let provider: KWExternalProvider

  fileprivate(set) var tokens: [KWTokenObject] = []

  fileprivate(set) var from: KWTokenObject
  fileprivate(set) var amountFrom: String = ""

  // Rate
  fileprivate(set) var estimatedRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double?

  // Gas Price
  fileprivate(set) var gasPriceType: KWGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KWGasCoordinator.shared.fastGas

  fileprivate(set) var gasLimit: BigInt = KWGasConfiguration.exchangeTokensGasLimitDefault
  var hasAgreed: Bool = false

  public init(
    receiverAddress: String,
    receiverToken: KWTokenObject,
    receiverTokenAmount: String?,
    network: KWEnvironment,
    signer: String? = nil,
    commissionID: String? = nil,
    dataType: KWDataType,
    keystore: KWKeystore
    ) {
    self.receiverAddress = receiverAddress
    self.receiverToken = receiverToken
    self.receiverTokenAmount = receiverTokenAmount
    self.network = network
    self.signer = signer
    self.commissionID = commissionID
    self.dataType = dataType
    self.keystore = keystore
    self.provider = KWExternalProvider(
      keystore: keystore,
      network: network
    )
    self.tokens = KWJSONLoadUtil.loadListSupportedTokensFromJSONFile(env: network)
    self.from = receiverToken

    super.init()

    self.gasLimit = {
      if self.from == self.receiverToken {
        // normal transfer
        if self.from.symbol == "ETH" { return KWGasConfiguration.transferETHGasLimitDefault }
        return KWGasConfiguration.transferTokenGasLimitDefault
      }
      return KWGasConfiguration.exchangeTokensGasLimitDefault
    }()
  }

  var payment: KWPayment {
    return KWPayment(
      from: self.from,
      to: self.receiverToken,
      account: nil,
      destWallet: self.receiverAddress,
      amountFrom: self.amountToSendMinRate,
      amountTo: self.receiverAmountBigInt,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: self.gasLimit,
      expectedRate: self.estimatedRate,
      chainID: self.network.chainID,
      commissionID: self.commissionID
    )
  }

  var amountToSendMinRate: BigInt {
    if self.from == self.receiverToken { return self.amountFromBigInt }
    if self.receiverTokenAmount == nil { return self.amountFromBigInt }
    guard let minRate = self.minRate, !minRate.isZero else { return self.amountFromBigInt }
    let expected: BigInt = {
      let received = self.receiverAmountBigInt ?? BigInt(0)
      let estimatedAmount = received * BigInt(10).power(self.from.decimals) / minRate
      return estimatedAmount
    }()
    return expected
  }
}

// MARK: Source data
extension KWPaymentMethodViewModel {
  var isFromAmountTextFieldEnabled: Bool { return self.receiverTokenAmount == nil }

  var amountFromBigInt: BigInt {
    return self.amountFrom.toBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var estimatedFromAmountBigInt: BigInt? {
    guard let receivedAmount = self.receiverAmountBigInt else { return nil }
    if self.from == self.receiverToken { return receivedAmount }
    guard let rate = self.estimatedRate, !rate.isZero else { return nil }
    return receivedAmount * BigInt(10).power(self.from.decimals) / rate
  }

  var estimatedFromAmountDisplay: String? {
    guard let estAmount = self.estimatedFromAmountBigInt else { return nil }
    return "\(estAmount.string(decimals: self.from.decimals, minFractionDigits: 0, maxFractionDigits: 9))"
  }
}

// MARK: Receiver Data
extension KWPaymentMethodViewModel {
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
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.address): ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: "\(self.receiverAddress.prefix(14))...\(self.receiverAddress.suffix(5))", attributes: addressValueAttributes))
    return attributedString
  }

  var isDestAmountLabelHidden: Bool { return self.receiverTokenAmount == nil }

  var receiverAmountBigInt: BigInt? {
    guard let receiverAmount = self.receiverTokenAmount else { return nil }
    return receiverAmount.toBigInt(decimals: self.receiverToken.decimals)
  }

  var destAmountAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    guard let amount = self.receiverTokenAmount else { return attributedString }
    let addressTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.segment,
      ]
    let addressValueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor(red: 102, green: 102, blue: 102),
      ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.amount): ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: "\(amount) \(self.receiverToken.symbol)", attributes: addressValueAttributes))
    return attributedString
  }

  var isEstimateDestAmountHidden: Bool { return self.receiverTokenAmount != nil }

  var estimateDestAmountAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let addressTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.segment,
    ]
    let addressValueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.action,
    ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.estimateDestAmount): ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: self.estimatedReceivedAmountDisplay, attributes: addressValueAttributes))
    return attributedString
  }

  // In case user has not given received amount
  var estimatedReceivedAmountBigInt: BigInt? {
    guard let rate = self.estimatedRate else { return nil }
    return rate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
  }

  var estimatedReceivedAmountDisplay: String {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "0 \(self.receiverToken.symbol)" }
    let string = estReceived.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return "\(string.prefix(12)) \(self.receiverToken.symbol)"
  }
}

// MARK: Rate
extension KWPaymentMethodViewModel {
  var isLoadingEstimatedRateHidden: Bool {
    if self.from.symbol == self.receiverToken.symbol { return true }
    return self.estimatedRate != nil
  }
  var isEstimatedRateHidden: Bool {
    if self.from.symbol == self.receiverToken.symbol { return true }
    return self.estimatedRate == nil
  }
  var estimatedExchangeRateText: String {
    let rateString: String = self.estimatedRate?.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 9) ?? "0"
    return "1 \(self.from.symbol) ~ \(rateString) \(self.receiverToken.symbol)"
  }

  var minRate: BigInt? {
    if self.from == self.receiverToken { return self.estimatedRate }
    if let double = self.minRatePercent, let estRate = self.estimatedRate {
      return estRate * BigInt(double) / BigInt(100)
    }
    return self.slippageRate
  }

  var minRateText: String? {
    return self.minRate?.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 9)
  }

  var currentMinRatePercentValue: Float {
    if self.from == self.receiverToken { return 100.0 }
    if let double = self.minRatePercent { return Float(floor(double)) }
    guard let estRate = self.estimatedRate, let slippageRate = self.slippageRate, !estRate.isZero else { return 100.0 }
    return Float(floor(Double(slippageRate * BigInt(100) / estRate)))
  }

  var currentMinRatePercentText: String {
    let value = self.currentMinRatePercentValue
    return "\(Int(floor(value)))%"
  }
}

// MARK: Validate data
extension KWPaymentMethodViewModel {
  var termsAndConditionsAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let addressTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.segment,
      ]
    let addressValueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.action,
      ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.agreeTo) ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: KWStringConfig.current.termsAndConditions, attributes: addressValueAttributes))
    return attributedString
  }

  // Validate amount
  var isAmountTooSmall: Bool {
    if self.receiverTokenAmount != nil { return false }
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.symbol == "ETH" {
      return self.amountFromBigInt <= BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    if self.receiverToken.symbol == "ETH" {
      return self.estimatedReceivedAmountBigInt ?? BigInt(0) <= BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    return false
  }

  // Validate Rate
  var isRateValid: Bool {
    if self.from == self.receiverToken { return true }
    if self.estimatedRate == nil || self.estimatedRate!.isZero { return false }
    if self.minRate == nil || self.minRate!.isZero { return false }
    return true
  }

  var isMinRateValidForTransaction: Bool {
    guard let minRate = self.minRate, !minRate.isZero else { return false }
    return true
  }

  // MARK: Helpers
  var tokenButtonAttributedText: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.black,
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.segment,
    ]
    attributedString.append(NSAttributedString(string: self.from.symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(self.from.name)", attributes: nameAttributes))
    return attributedString
  }
}

// MARK: Update data
extension KWPaymentMethodViewModel {
  func updateSelectedToken(_ token: KWTokenObject) {
    if self.from == token { return }
    self.from = token
    self.amountFrom = ""
    self.estimatedRate = nil
    self.slippageRate = nil
    self.gasLimit = {
      if self.receiverToken != self.from { return KWGasConfiguration.exchangeTokensGasLimitDefault }
      if self.from.symbol == "ETH" { return KWGasConfiguration.transferETHGasLimitDefault }
      return KWGasConfiguration.transferTokenGasLimitDefault
    }()
  }

  func updateFromAmount(_ amount: String) {
    self.amountFrom = amount
  }

  func updateSelectedGasPriceType(_ type: KWGasPriceType) {
    self.gasPriceType = type
    switch type {
    case .fast:
      self.gasPrice = KWGasCoordinator.shared.fastGas
    case .medium:
      self.gasPrice = KWGasCoordinator.shared.mediumGas
    case .slow:
      self.gasPrice = KWGasCoordinator.shared.slowGas
    default: break
    }
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.gasPriceType = .custom
  }

  func updateExchangeRate(for from: KWTokenObject, to: KWTokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    if from == self.from, to == self.receiverToken, amount == self.amountFromBigInt {
      self.estimatedRate = rate
      if rate.isZero {
        self.slippageRate = slippageRate
      } else {
        var percent = Double(slippageRate * BigInt(100) / rate)
        if percent == 0 { percent = 97.0 }
        self.slippageRate = rate * BigInt(Int(floor(percent))) / BigInt(100)
      }
    }
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: KWTokenObject, to: KWTokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.receiverToken, amount == self.amountFromBigInt {
      self.gasLimit = gasLimit
    }
  }

  func updateEstimatedGasPrices() {
    switch self.gasPriceType {
    case .fast: self.gasPrice = KWGasCoordinator.shared.fastGas
    case .medium: self.gasPrice = KWGasCoordinator.shared.mediumGas
    case .slow: self.gasPrice = KWGasCoordinator.shared.slowGas
    default: break
    }
  }

  func updateSupportedTokens(_ tokens: [KWTokenObject]) { self.tokens = tokens }

  func getExpectedRateRequest(completion: @escaping () -> Void) {
    if self.from == self.receiverToken {
      if let rate = "1".toBigInt(decimals: self.from.decimals) {
        self.estimatedRate = rate
        self.slippageRate = rate * BigInt(97) / BigInt(100)
      }
      print("Same tokens")
      completion()
      return
    }
    let from = self.from
    let to = self.receiverToken
    let amount = self.amountFromBigInt
    print("Get expected rate for token")
    self.provider.getExpectedRate(from: from, to: to, amount: amount) { result in
      if case .success(let data) = result {
        self.updateExchangeRate(
          for: from,
          to: to,
          amount: amount,
          rate: data.0,
          slippageRate: data.1
        )
        print("Success loading expected rate with \(data.0.fullString(decimals: to.decimals))")
      } else if case .failure(let error) = result {
        print("Error loading expected rate with error: \(error.description)")
      }
      completion()
    }
  }

  func getEstimatedGasLimit(completion: @escaping () -> Void) {
    if self.from == self.receiverToken {
      print("Estimated gas for transfer token")
      let payment = self.payment
      self.provider.getTransferEstimateGasLimit(for: payment) { result in
        if case .success(let gasLimit) = result {
          self.updateEstimateGasLimit(
            for: payment.from,
            to: payment.to,
            amount: payment.amountFrom,
            gasLimit: gasLimit
          )
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
      let payment = self.payment
      self.provider.getSwapEstimateGasLimit(for: payment) { result in
        if case .success(let gasLimit) = result {
          self.updateEstimateGasLimit(
            for: payment.from,
            to: payment.to,
            amount: payment.amountFrom,
            gasLimit: gasLimit
          )
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
