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
  fileprivate(set) var minRatePercent: Double?

  // Gas Price
  fileprivate(set) var gasPriceType: KWGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KWGasCoordinator.shared.fastGas

  fileprivate(set) var gasLimit: BigInt = KWGasConfiguration.exchangeTokensGasLimitDefault
  var hasAgreed: Bool = false

  fileprivate(set) var userCap: BigInt = BigInt(0)
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

    self.gasLimit = {
      if self.from == self.to {
        // normal transfer
        if self.from.isETH { return KWGasConfiguration.transferETHGasLimitDefault }
        return KWGasConfiguration.transferTokenGasLimitDefault
      }
      return KWGasConfiguration.exchangeTokensGasLimitDefault
    }()
  }

  var transaction: KWTransaction {
    return KWTransaction(
      from: self.from,
      to: self.to,
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

  // The actual amount to send is computed using min rate, however, the est amount user need to pay is still the same
  var amountToSendMinRate: BigInt {
    if self.from == self.to || self.dataType == .swap  || self.toAmount == nil {
      return self.amountFromBigInt
    }
    if self.dataType == .buy && self.toAmount == nil {
      return self.amountFromBigInt
    }
    guard let minRate = self.minRate, !minRate.isZero else { return self.amountFromBigInt }
    let expected: BigInt = {
      let received = self.receiverAmountBigInt ?? BigInt(0)
      let estimatedAmount = received * BigInt(10).power(self.from.decimals) / minRate
      return estimatedAmount
    }()
    return expected
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
    return self.receiverToken == nil ? 124.0 : 74.0
  }

  /*
   Hidden if receive token is fixed
   */
  var heightForReceiverTokenView: CGFloat {
    return self.receiverToken == nil ? 50.0 : 0.0
  }

  /*
   TO button when both from and to tokens are modifiable
  */
  var isToButtonHidden: Bool { return self.receiverToken != nil }

  /*
   Enabled if receive amount is empty, disabled otherwise
   */
  var isFromAmountTextFieldEnabled: Bool { return self.toAmount == nil }
  var fromAmountTextFieldColor: UIColor {
    if self.isFromAmountTextFieldEnabled {
      return KWThemeConfig.current.amountTextFieldEnable
    }
    return KWThemeConfig.current.amountTextFieldDisable
  }

  /*
   Either PAY WITH or SWAP
   */
  var transactionTypeText: String {
    return self.dataType == .swap ? KWStringConfig.current.swapUppercased : KWStringConfig.current.payWith
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

// MARK: Receiver Data
extension KWPaymentMethodViewModel {
  /*
   Hidden if swap, or buy with no amount specified, otherwise not hidden
   */
  var isDestDataViewHidden: Bool {
    if self.dataType == .swap { return true }
    if self.dataType == .buy && self.toAmount == nil { return true }
    return false
  }

  /*
   Hidden, show 1 line data or 2 lines data
  */
  var heightForDestDataView: CGFloat {
    if self.isDestDataViewHidden { return 0.0 }
    if self.dataType == .buy { return 80.0 }
    // now data type is pay
    var height: CGFloat = 100.0 // text and address
    if !self.isDestAmountLabelHidden { height += 24.0 }
    if !self.isProductNameHidden { height += 24.0 }
    height += self.heightProductAvatarImage
    return height
  }

  /*
   YOU ARE ABOUT TO PAY or YOU ARE ABOUT TO BUY
   */
  var destDataTitleLabelString: String {
    if self.isDestDataViewHidden { return "" }
    if self.dataType == .pay { return KWStringConfig.current.youAreAboutToPay.uppercased() }
    if self.dataType == .buy { return KWStringConfig.current.youAreAboutToBuy.uppercased() }
    return ""
  }

  /*
   Dest address label for pay widget only
  */
  var isDestAddressLabelHidden: Bool { return self.receiverAddress.isEmpty }

  /*
   Dest address label for pay widget only
  */
  var destAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.address): ", attributes: self.dataNameAttributes))
    attributedString.append(NSAttributedString(string: "\(self.receiverAddress.prefix(14))...\(self.receiverAddress.suffix(5))", attributes: self.dataValueAttributes))
    return attributedString
  }

  /*
   Dest amount label for pay or buy widget
  */
  var isDestAmountLabelHidden: Bool { return self.toAmount == nil }

  /*
   nil if receive amount is not set, otherwise computed from toAmount
   */
  var receiverAmountBigInt: BigInt? {
    guard let receiverAmount = self.toAmount else { return nil }
    return BigInt(receiverAmount * pow(10.0, Double(self.to.decimals)))
  }

  var topPaddingForDestAmountLabel: CGFloat {
    return self.isDestAddressLabelHidden ? 8 : 32
  }

  var destAmountAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    guard let amount = self.toAmount else { return attributedString }
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.amount): ", attributes: self.dataNameAttributes))
    attributedString.append(NSAttributedString(string: "\(amount) \(self.to.symbol)", attributes: self.dataValueAttributes))
    return attributedString
  }

  var isEstimateDestAmountHidden: Bool {
    if self.receiverToken == nil { return true }
    return self.toAmount != nil
  }

  var estimateDestAmountAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let addressTextAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.segment,
    ]
    let addressValueAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.action,
    ]
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.estimateDestAmount): ", attributes: addressTextAttributes))
    attributedString.append(NSAttributedString(string: self.estimatedReceivedAmountWithSymbolString, attributes: addressValueAttributes))
    return attributedString
  }

  /*
   In case user has not given received amount, estimated receive amount is computed from amountFrom and rate
   */
  var estimatedReceivedAmountBigInt: BigInt? {
    guard let rate = self.estimatedRate else { return nil }
    return rate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
  }

  var estimatedReceiverAmountString: String {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return "0" }
    let string = estReceived.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return "\(string.prefix(12))"
  }

  fileprivate var estimatedReceivedAmountWithSymbolString: String {
    return "\(self.estimatedReceiverAmountString) \(self.to.symbol)"
  }

  var isProductNameHidden: Bool { return self.productName == nil }
  var productNameAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    guard let productName = self.productName else { return attributedString }
    attributedString.append(NSAttributedString(string: "\(KWStringConfig.current.productName): ", attributes: self.dataNameAttributes))
    attributedString.append(NSAttributedString(string: "\(productName)", attributes: self.dataValueAttributes))
    return attributedString
  }
  var topPaddingProductNameLabel: CGFloat {
    return self.toAmount == nil ? 8.0 : 32.0
  }

  var isProductAvatarImageViewHidden: Bool { return self.productAvatarImage == nil }
  var topPaddingProductAvatar: CGFloat {
    if self.isDestAmountLabelHidden && self.isProductNameHidden { return 8.0 }
    if !self.isDestAmountLabelHidden && !self.isProductNameHidden { return 64.0 }
    return 32.0
  }
  var heightProductAvatarImage: CGFloat {
    guard let image = self.productAvatarImage else { return 0.0 }
    return image.size.height
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

  var minRate: BigInt? {
    if self.from == self.to { return self.estimatedRate }
    if let double = self.minRatePercent, let estRate = self.estimatedRate {
      return estRate * BigInt(double) / BigInt(100)
    }
    return self.slippageRate
  }

  var slippageRateText: String? {
    return self.slippageRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: 9)
  }

  var minRateText: String? {
    return self.minRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: 9)
  }

  var currentMinRatePercentValue: Float {
    if self.from == self.to { return 100.0 }
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
    if self.toAmount != nil { return false }
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.symbol == "ETH" {
      return self.amountFromBigInt < BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    if self.to.symbol == "ETH" {
      return self.estimatedReceivedAmountBigInt ?? BigInt(0) < BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
    }
    guard let rateETH = KWRateCoordinator.shared.rates.first(where: { $0.symbol == self.from.symbol }) else { return false }
    let rateBig: BigInt = BigInt(rateETH.rate * pow(10.0, 18.0))
    let valueInETH = rateBig * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    return valueInETH <= BigInt(0.001 * Double(KWEthereumUnit.ether.rawValue))
  }

  // Validate Rate
  var isRateValid: Bool {
    if self.from == self.to { return true }
    if self.estimatedRate == nil || self.estimatedRate!.isZero { return false }
    if self.minRate == nil || self.minRate!.isZero { return false }
    return true
  }

  var isMinRateValidForTransaction: Bool {
    guard let minRate = self.minRate, !minRate.isZero else { return false }
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

    self.gasLimit = {
      if self.to != self.from { return KWGasConfiguration.exchangeTokensGasLimitDefault }
      if self.from.symbol == "ETH" { return KWGasConfiguration.transferETHGasLimitDefault }
      return KWGasConfiguration.transferTokenGasLimitDefault
    }()
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
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
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
    if from == self.from, to == self.to, amount == self.amountFromBigInt {
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

  func getEstimatedGasLimit(completion: @escaping () -> Void) {
    if self.dataType == .pay {
      print("Estimated gas for pay transaction")
      let transaction = self.transaction
      self.provider.getPayEstimateGasLimit(for: transaction) { result in
        if case .success(let gasLimit) = result {
          self.updateEstimateGasLimit(
            for: transaction.from,
            to: transaction.to,
            amount: transaction.amountFrom,
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
      return
    }
    if self.from == self.to {
      print("Estimated gas for transfer token")
      let transaction = self.transaction
      self.provider.getTransferEstimateGasLimit(for: transaction) { result in
        if case .success(let gasLimit) = result {
          self.updateEstimateGasLimit(
            for: transaction.from,
            to: transaction.to,
            amount: transaction.amountFrom,
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
      let transaction = self.transaction
      self.provider.getSwapEstimateGasLimit(for: transaction) { result in
        if case .success(let gasLimit) = result {
          self.updateEstimateGasLimit(
            for: transaction.from,
            to: transaction.to,
            amount: transaction.amountFrom,
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
