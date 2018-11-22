//
//  KWImportViewModel.swift
//  KyberPayiOS
//
//  Created by Manh Le on 17/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result

public class KWImportViewModel: NSObject {
  let network: KWEnvironment

  let dataType: KWDataType
  let signer: String?
  let commissionID: String?

  var tokens: [KWTokenObject]
  let transaction: KWTransaction
  let keystore: KWKeystore
  let provider: KWExternalProvider

  var selectedType: Int = 0
  var jsonData: String = ""

  private(set) var account: Account?
  private(set) var balance: BigInt? = nil

  private(set) var userCap: BigInt?

  public init(
    dataType: KWDataType,
    network: KWEnvironment,
    signer: String? = nil,
    commissionID: String? = nil,
    keystore: KWKeystore,
    tokens: [KWTokenObject],
    transaction: KWTransaction
    ) {
    self.dataType = dataType
    self.network = network
    self.signer = signer
    self.commissionID = commissionID
    self.keystore = keystore
    self.transaction = transaction
    self.tokens = tokens
    self.provider = KWExternalProvider(keystore: keystore, network: network)
  }

  func clearWallets(completion: @escaping () -> Void) {
    if self.keystore.account == nil {
      completion()
      return
    }
    self.keystore.accounts.forEach { account in
      self.keystore.delete(account: account, completion: { _ in
        if self.keystore.account == nil {
          completion()
        }
      })
    }
  }

  func updateSelectedType(_ type: Int) {
    self.selectedType = type
  }

  func updateJSONData(_ data: String) {
    self.jsonData = data
  }

  var isImportJSONButtonHidden: Bool {
    return self.selectedType != 0 || self.account != nil
  }
  var isImportJSONTextFieldHidden: Bool {
    return self.selectedType != 0 || self.account != nil
  }

  var isImportPrivateKeyTextFieldHidden: Bool {
    return self.selectedType != 1 || self.account != nil
  }
  var isImportSeedsTextFieldHidden: Bool {
    return self.selectedType != 2 || self.account != nil
  }

  var actionButtonTitle: String {
    return self.account == nil ? KWStringConfig.current.unlock : KWStringConfig.current.next
  }

  // Imported account
  var hasAccount: Bool { return self.account != nil }
  var displayBalanceAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let string = balance?.string(
      decimals: self.transaction.from.decimals,
      maxFractionDigits: min(6, self.transaction.from.decimals)
      ) ?? "0"
    let balanceAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.background,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .medium),
    ]
    let symbolAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium),
    ]
    attributedString.append(NSAttributedString(string: "\(string.prefix(12)) ", attributes: balanceAttributes))
    attributedString.append(NSAttributedString(string: self.transaction.from.symbol, attributes: symbolAttributes))
    return attributedString
  }

  var displaySrcAddress: String {
    guard let address = self.account?.address.description else { return "--" }
    return "\(address.prefix(24))...\(address.suffix(6))"
  }

  var isBalanceEnoughWithMinRateAmountFrom: Bool {
    guard let balance = self.balance else { return false }
    let amountFrom: BigInt = self.transaction.amountFrom
    return amountFrom <= balance
  }

  var isBalanceEnoughWithRealAmountFrom: Bool {
    guard let balance = self.balance else { return false }
    let amountFrom: BigInt = self.transaction.expectedFromAmount(dataType: self.dataType)
    return amountFrom <= balance
  }

  var isAmountValidWithCap: Bool {
    guard let cap = self.userCap else { return true }// if can not load, consider as ok
    guard let rateETH = KWRateCoordinator.shared.rates.first(where: { $0.symbol == self.transaction.from.symbol }) else { return true }
    let rateBig: BigInt = BigInt(rateETH.rate * pow(10.0, 18.0))
    let valueInETH = rateBig * self.transaction.amountFrom / BigInt(10).power(self.transaction.from.decimals)
    return valueInETH <= cap
  }

  func importWallet(importType: KWImportType, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {
    self.keystore.importWallet(type: importType) { result in
      switch result {
      case .success(let account):
        self.account = account
      default: break
      }
      completion(result)
    }
  }

  func removeWallets(completion: @escaping () -> Void) {
    self.keystore.removeAllAccounts {
      self.account = nil
      completion()
    }
  }

  func getBalance(completion: @escaping () -> Void) {
    print("Getting balance for \(self.transaction.from.symbol)")
    guard let address = self.account?.address else {
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
          if let addr = self.account?.address, addr == address {
            self.balance = bal
          }
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
            if let addr = self.account?.address, addr == address {
              self.balance = bal
            }
          case .failure(let error):
            print("Getting \(self.transaction.from.symbol) balance failed error: \(error.localizedDescription)")
          }
          completion()
      }
    }
  }

  func getUserCapInWei(completion: @escaping () -> Void) {
    print("Getting user cap in wei")
    guard let address = self.account?.address else {
      print("Done getting user cap in wei")
      completion()
      return
    }
    self.provider.generalProvider.getUserCapInWei(for: address) { [weak self] result in
      guard let `self` = self else { return }
      print("Done getting user cap in wei")
      switch result {
      case .success(let resp):
        self.userCap = resp
      case .failure: break
      }
      completion()
    }
  }
}
