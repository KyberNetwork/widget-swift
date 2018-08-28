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

  let signer: String?
  let commissionID: String?

  var tokens: [KWTokenObject]
  let payment: KWPayment
  let keystore: KWKeystore
  let provider: KWExternalProvider

  var selectedType: Int = 0
  var jsonData: String = ""

  private(set) var account: Account?
  private(set) var balance: BigInt? = nil

  public init(
    network: KWEnvironment,
    signer: String? = nil,
    commissionID: String? = nil,
    keystore: KWKeystore,
    tokens: [KWTokenObject],
    payment: KWPayment
    ) {
    self.network = network
    self.signer = signer
    self.commissionID = commissionID
    self.keystore = keystore
    self.payment = payment
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
      decimals: self.payment.from.decimals,
      maxFractionDigits: min(6, self.payment.from.decimals)
      ) ?? "0"
    let balanceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.background,
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 32, weight: .medium),
    ]
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: .medium),
    ]
    attributedString.append(NSAttributedString(string: "\(string.prefix(12)) ", attributes: balanceAttributes))
    attributedString.append(NSAttributedString(string: self.payment.from.symbol, attributes: symbolAttributes))
    return attributedString
  }

  var displaySrcAddress: String {
    guard let address = self.account?.address.description else { return "--" }
    return "\(address.prefix(24))...\(address.suffix(6))"
  }

  var isBalanceEnough: Bool {
    guard let balance = self.balance else { return false }
    let amountFrom: BigInt = {
      if self.payment.from == self.payment.to { return self.payment.amountFrom }
      if self.payment.amountTo == nil { return self.payment.amountFrom }
      // amountFrom is computed using min rate
      guard let minRate = self.payment.minRate, let expectedRate = self.payment.expectedRate, !expectedRate.isZero else {
        return BigInt(0)
      }
      return self.payment.amountFrom * minRate / expectedRate
    }()
    return amountFrom <= balance
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
    print("Getting balance for \(self.payment.from.symbol)")
    guard let address = self.account?.address else {
      print("Address is nil")
      completion()
      return
    }
    if self.payment.from.isETH {
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
        for: Address(string: self.payment.from.address)!,
        address: address) { result in
          print("Done getting \(self.payment.from.symbol) balance")
          switch result {
          case .success(let bal):
            print("Getting \(self.payment.from.symbol) balance susccess")
            if let addr = self.account?.address, addr == address {
              self.balance = bal
            }
          case .failure(let error):
            print("Getting \(self.payment.from.symbol) balance failed error: \(error.localizedDescription)")
          }
          completion()
      }
    }
  }
}
