//
//  KWTransaction.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import BigInt
import TrustCore
import TrustKeystore

public struct KWTransaction {
  // Pay from token to token, from and to can be the same
  let from: KWTokenObject
  let to: KWTokenObject
  // source wallet to pay
  let account: Account?
  // wallet to pay to
  let destWallet: String
  // Amount from
  let amountFrom: BigInt
  // Only set this value if you want to pay a fixed amount
  let amountTo: BigInt?
  // Only if from != to
  let minRate: BigInt?

  let gasPrice: BigInt?
  let gasLimit: BigInt?
  let expectedRate: BigInt?

  let chainID: Int
  let commissionID: String?

  func expectedFromAmount(dataType: KWDataType) -> BigInt {
    // KyberSwap
    if dataType == .swap { return self.amountFrom }
    // Buy but not fixed receive amount
    if dataType == .buy && self.amountTo == nil { return self.amountFrom }
    // Normal transfer
    if self.from == self.to { return self.amountFrom }
    // Not fixed receive amount
    if self.amountTo == nil { return self.amountFrom }
    guard let minRate = self.minRate, let expectedRate = self.expectedRate, !expectedRate.isZero else {
      return BigInt(0)
    }
    return self.amountFrom * minRate / expectedRate
  }

  func newObject(with account: Account) -> KWTransaction {
    // if dest wallet is empty -> kyberswap transaction
    let destAddr: String = self.destWallet.isEmpty ? account.address.description : self.destWallet
    return KWTransaction(
      from: self.from,
      to: self.to,
      account: account,
      destWallet: destAddr,
      amountFrom: self.amountFrom,
      amountTo: self.amountTo,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: self.gasLimit,
      expectedRate: self.expectedRate,
      chainID: self.chainID,
      commissionID: self.commissionID
    )
  }
}
