//
//  KWPayment.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import BigInt
import TrustCore
import TrustKeystore

public struct KWPayment {
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

  func newObject(with account: Account) -> KWPayment {
    // if dest wallet is empty -> kyberswap transaction
    let destAddr: String = self.destWallet.isEmpty ? account.address.description : self.destWallet
    return KWPayment(
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
