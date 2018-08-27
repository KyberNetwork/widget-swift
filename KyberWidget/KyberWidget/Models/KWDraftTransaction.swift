//
//  KWDraftTransaction.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import BigInt
import TrustCore
import TrustKeystore

public struct KWDraftTransaction {
  let value: BigInt
  let account: Account
  let to: Address?
  let nonce: Int
  let data: Data
  let gasPrice: BigInt
  let gasLimit: BigInt
  let chainID: Int
}
