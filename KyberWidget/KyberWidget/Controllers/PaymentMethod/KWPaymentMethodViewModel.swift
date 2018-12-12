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
  let defaultTokenIconImg = UIImage(named: "default_token", in: Bundle.framework, compatibleWith: nil)

  let receiverAddress: String
  let receiverToken: KWTokenObject?
  let toAmount: Double?
  let network: KWEnvironment
  let dataType: KWDataType

  let signer: String?
  let commissionID: String?
  let productName: String?
  let productAvatar: String?
  fileprivate(set) var productAvatarImage: UIImage?

  let keystore: KWKeystore
  let provider: KWExternalProvider

  fileprivate(set) var tokens: [KWTokenObject] = []

  fileprivate(set) var from: KWTokenObject
  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var to: KWTokenObject

  // Rate
  fileprivate(set) var estimatedRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?

  var hasAgreed: Bool = false

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

  public init(
    receiverAddress: String,
    receiverToken: KWTokenObject?,
    toAmount: Double?,
    network: KWEnvironment,
    signer: String? = nil,
    commissionID: String? = nil,
    productName: String?,
    productAvatar: String?,
    productAvatarImage: UIImage?,
    dataType: KWDataType,
    tokens: [KWTokenObject],
    keystore: KWKeystore
    ) {
    self.receiverAddress = receiverAddress
    self.receiverToken = receiverToken
    self.toAmount = toAmount
    self.network = network
    self.signer = signer
    self.commissionID = commissionID
    self.productName = productName
    self.productAvatar = productAvatar
    self.productAvatarImage = productAvatarImage?.resizeImage(toWidth: UIScreen.main.bounds.width - 44.0)

    self.dataType = dataType
    self.keystore = keystore
    self.provider = KWExternalProvider(
      keystore: keystore,
      network: network
    )

    let eth = tokens.first(where: { $0.isETH })!
    let knc = tokens.first(where: { $0.isKNC })!

    self.tokens = tokens
    if let token = receiverToken {
      self.from = token
      self.to = token
      if dataType == .swap || dataType == .buy {
        // if kyberswap or buy, from and to should be different tokens
        self.from = token.isETH ? knc : eth
      }
    } else {
      self.from = eth
      self.to = knc
    }

    super.init()
  }

  var transaction: KWTransaction {
    return KWTransaction(
      from: self.from,
      to: self.to,
      account: nil,
      destWallet: self.receiverAddress,
      amountFrom: self.amountFromBigInt,
      amountTo: self.receiverAmountBigInt,
      minRate: nil,
      gasPrice: nil,
      gasLimit: nil,
      expectedRate: self.estimatedRate,
      chainID: self.network.chainID,
      commissionID: self.commissionID
    )
  }

  var navigationTitle: String {
    switch self.dataType {
    case .pay: return KWStringConfig.current.payment
    case .swap: return KWStringConfig.current.swap
    case .buy: return KWStringConfig.current.buy
    }
  }
}

// MARK: Source data
extension KWPaymentMethodViewModel {
  /*
   Depends on can choose receive token or not
   */
  var heightForTokenData: CGFloat {
    return self.dataType != .pay ? 124.0 : 74.0
  }

  /*
   Hidden if receive token is fixed
   */
  var heightForReceiverTokenView: CGFloat {
    return self.dataType != .pay ? 50.0 : 0.0
  }

  /*
   TO button when both from and to tokens are modifiable
  */
  var isToButtonHidden: Bool {
    return self.dataType == .pay
  }

  /*
   Enabled if receive amount is empty, disabled otherwise
   */
  var isFromAmountTextFieldEnabled: Bool {
    return self.toAmount == nil
  }

  var fromAmountTextFieldColor: UIColor {
    if self.isFromAmountTextFieldEnabled {
      return KWThemeConfig.current.amountTextFieldEnable
    }
    return KWThemeConfig.current.amountTextFieldDisable
  }

  /*
   top string text for pay, swap, buy
   */
  var topStringText: String {
    switch self.dataType {
    case .pay: return KWStringConfig.current.payTopString
    case .swap: return KWStringConfig.current.swapTopString
    case .buy: return String(format: KWStringConfig.current.buyTopString, self.receiverToken?.symbol ?? "")
    }
  }

  var topStringTextColor: UIColor {
    switch self.dataType {
    case .pay: return KWThemeConfig.current.payTopTextColor
    case .swap: return KWThemeConfig.current.swapTopTextColor
    case .buy: return KWThemeConfig.current.buyTopTextColor
    }
  }

  // convert from amount to BigInt
  var amountFromBigInt: BigInt {
    return self.amountFrom.toBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  /*
   From amount is computed instead of typing if receive amount is fixed
   */
  var estimatedFromAmountBigInt: BigInt? {
    guard let receivedAmount = self.receiverAmountBigInt else { return nil }
    if self.from == self.to { return receivedAmount }
    guard let rate = self.estimatedRate, !rate.isZero else { return nil }
    return receivedAmount * BigInt(10).power(self.from.decimals) / rate
  }

  /*
   Display string for amount computed using expected rate & receive amount
   If receive amount is nil, use amountFrom
   */
  var estimatedFromAmountDisplay: String? {
    guard let estAmount = self.estimatedFromAmountBigInt else { return nil }
    return "\(estAmount.string(decimals: self.from.decimals, minFractionDigits: 0, maxFractionDigits: 9))"
  }
}

// MARK: PAY order details data view
extension KWPaymentMethodViewModel {
  var isPayOrderDetailsContainerHidden: Bool {
    return self.dataType != .pay
  }

  var payOrderDetailsTextContainerViewHeight: CGFloat {
    return self.dataType == .pay ? 50.0 : 0.0
  }

  var payOrderDetailsTextString: String {
    return KWStringConfig.current.orderDetails
  }

  var bottomPaddingPayDestAddressLabel: CGFloat {
    return self.dataType == .pay ? 24.0 : 0.0
  }

  var isProductNameHidden: Bool {
    return self.productName == nil || self.dataType != .pay
  }

  var topPaddingProductName: CGFloat {
    return isProductNameHidden ? 0.0 : 24.0
  }

  var isProductAvatarImageViewHidden: Bool {
    return self.productAvatarImage == nil || self.dataType != .pay
  }

  var topPaddingProductAvatar: CGFloat {
    return self.isProductAvatarImageViewHidden ? 0.0 : 24.0
  }

  var heightProductAvatarImage: CGFloat {
    if self.dataType != .pay { return 0.0 }
    guard let image = self.productAvatarImage else { return 0.0 }
    return image.size.height
  }

  /*
   nil if receive amount is not set, otherwise computed from toAmount
   */
  var receiverAmountBigInt: BigInt? {
    guard let receiverAmount = self.toAmount else { return nil }
    return BigInt(receiverAmount * pow(10.0, Double(self.to.decimals)))
  }

  var topPaddingForDestAmountLabel: CGFloat {
    return self.dataType == .pay ? 54.0 : 0.0
  }

  var payDestAmountText: String {
    if self.dataType != .pay { return "" }
    if let amount = self.toAmount {
      return "\(amount) \(self.to.symbol)"
    }
    return self.estimatedReceivedAmountWithSymbolString
  }

  /*
   In case user has not given received amount, estimated receive amount is computed from amountFrom and rate
   */
  var estimatedReceivedAmountBigInt: BigInt? {
    if let amountTo = self.receiverAmountBigInt { return amountTo }
    guard let rate = self.estimatedRate else { return nil }
    return rate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
  }

  var estimatedReceiverAmountString: String {
    if let toAmount = self.toAmount {
      return "\(toAmount)"
    }
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "0" }
    let string = estReceived.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return "\(string.prefix(12))"
  }

  fileprivate var estimatedReceivedAmountWithSymbolString: String {
    return "\(self.estimatedReceiverAmountString) \(self.to.symbol)"
  }

  /*
   Dest amount label for pay or buy widget
   */
  var isDestAmountLabelHidden: Bool {
    return self.dataType != .pay
  }

  /*
   Dest address label for pay widget only
   */
  var payDestAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.address): ", attributes: self.dataNameAttributes))
    attributedString.append(NSAttributedString(string: "\(self.receiverAddress.prefix(14))...\(self.receiverAddress.suffix(5))", attributes: self.dataValueAttributes))
    return attributedString
  }

  var payDestAddressLabelHidden: Bool {
    return self.dataType != .pay
  }

  var topPaddingPayDestAddressLabel: CGFloat {
    return self.dataType == .pay ? 70.0 : 0.0
  }
}

// MARK: Rate
extension KWPaymentMethodViewModel {
  var isLoadingEstimatedRateHidden: Bool {
    if self.from.symbol == self.to.symbol { return true }
    return self.estimatedRate != nil
  }

  var isEstimatedRateHidden: Bool {
    if self.from.symbol == self.to.symbol { return true }
    return self.estimatedRate == nil
  }

  var estimatedExchangeRateText: String {
    let rateString: String = self.estimatedRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: 9) ?? "0"
    return "1 \(self.from.symbol) ~ \(rateString) \(self.to.symbol)"
  }
}

// MARK: Validate data
extension KWPaymentMethodViewModel {
  var termsAndConditionsAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let addressTextAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.segment,
      ]
    let addressValueAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.action,
      ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.agreeTo) ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: KWStringConfig.current.termsAndConditions, attributes: addressValueAttributes))
    return attributedString
  }

  // Validate amount (not use for checking amount for now)
  var isAmountTooSmall: Bool {
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.symbol == "ETH" {
      return self.amountFromBigInt < BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    if self.to.symbol == "ETH" {
      return self.estimatedReceivedAmountBigInt ?? BigInt(0) < BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    guard let rateETH = KWRateCoordinator.shared.rates.first(where: { $0.from == self.from.symbol && $0.to == "ETH" }) else { return true }
    print("Rate in ETH for \(self.from.symbol): \(rateETH.rate)")
    let rateBig: BigInt = BigInt(rateETH.rate * pow(10.0, 18.0))
    let valueInETH = rateBig * self.amountFromBigInt
    print("Value in ETH: \(valueInETH.string(decimals: 18, maxFractionDigits: 6))")
    let valueMinETH = BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue)) * BigInt(10).power(self.from.decimals)
    return valueInETH < valueMinETH
  }

  // Validate Rate
  var isRateValid: Bool {
    if self.from == self.to { return true }
    if self.estimatedRate == nil || self.estimatedRate!.isZero { return false }
    return true
  }

  // MARK: Helpers
  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.black,
    ]
    let nameAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.segment,
    ]
    let symbol: String = isSource ? self.from.symbol : self.to.symbol
    let name: String = isSource ? self.from.name : self.to.name
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }
}

// MARK: Update data
extension KWPaymentMethodViewModel {
  @discardableResult
  func updateSelectedToken(_ token: KWTokenObject, isSource: Bool) -> Bool {
    if self.receiverToken != nil && !isSource { return false } // not allow to update receiver token
    if self.from == token && isSource { return false }
    if self.to == token && !isSource { return false }

    let oldFrom = self.from
    let oldTo = self.to

    if isSource { self.from = token } else { self.to = token }

    /*
     For swap or buy, the from and to tokens must be different as we are not supporting swapping the same token
     */
    if self.dataType == .swap && self.from == self.to {
      if isSource {
        // just updata from token
        self.to = oldFrom
      } else {
        // just update to token
        self.from = oldTo
      }
    } else if self.dataType == .buy && self.from == self.to {
      // For buy, can not change from token but from must be different from to
      self.from = oldFrom
    }

    // From token is changed, should reset the amountFrom to empty
    if self.from != oldFrom { self.amountFrom = "" }

    // Reset rates
    self.estimatedRate = nil
    self.slippageRate = nil
    return true
  }

  func updateDefaultPairTokens(from: KWTokenObject, to: KWTokenObject) {
    if self.receiverToken == nil {
      // Only update if receiver token is nil
      self.updateSelectedToken(to, isSource: false)
    }
    self.updateSelectedToken(from, isSource: true)
  }

  func updateFromAmount(_ amount: String) { self.amountFrom = amount }

  func updateExchangeRate(for from: KWTokenObject, to: KWTokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
      self.estimatedRate = rate
      if rate.isZero {
        self.slippageRate = slippageRate
      } else {
        var percent = Double(slippageRate * BigInt(100) / rate)
        if percent == 0 { percent = 97.0 }
        percent = max(percent, 10.0)
        self.slippageRate = rate * BigInt(Int(floor(percent))) / BigInt(100)
      }
    }
  }

  func updateSupportedTokens(_ tokens: [KWTokenObject]) { self.tokens = tokens }

  // MARK: Getting data from node
  func getExpectedRateRequest(completion: @escaping () -> Void) {
    if self.from == self.to {
      if let rate = "1".toBigInt(decimals: self.from.decimals) {
        self.estimatedRate = rate
        self.slippageRate = rate * BigInt(97) / BigInt(100)
      }
      print("Same tokens")
      completion()
      return
    }
    let from = self.from
    let to = self.to
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

  func getProductAvatarIfNeeded(completion: @escaping (Bool) -> Void) {
    guard let urlString = self.productAvatar, let url = URL(string: urlString), self.productAvatarImage == nil else {
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

  func getTrackerRates(completion: @escaping (Bool) -> Void) {
    DispatchQueue.global(qos: .background).async {
      KWRateCoordinator.shared.fetchTrackerRates(env: self.network) { result in
        DispatchQueue.main.async {
          if case .success = result {
            completion(true)
          } else {
            completion(false)
          }
        }
      }
    }
  }
}
