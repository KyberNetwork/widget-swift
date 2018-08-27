//
//  BigInt+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt

extension BigInt {

  func string(units: KWEthereumUnit, minFractionDigits: Int = 0, maxFractionDigits: Int) -> String {
    let formatter = KWNumberUtil.shared
    formatter.maximumFractionDigits = maxFractionDigits
    formatter.minimumFractionDigits = minFractionDigits
    return formatter.string(from: self, units: units)
  }

  func string(decimals: Int, minFractionDigits: Int = 0, maxFractionDigits: Int) -> String {
    let formatter = KWNumberUtil.shared
    formatter.maximumFractionDigits = maxFractionDigits
    formatter.minimumFractionDigits = minFractionDigits
    return formatter.string(from: self, decimals: decimals)
  }

  func shortString(units: KWEthereumUnit, maxFractionDigits: Int = 5) -> String {
    return self.string(units: units, maxFractionDigits: maxFractionDigits)
  }

  func shortString(decimals: Int, maxFractionDigits: Int = 5) -> String {
    return self.string(decimals: decimals, maxFractionDigits: maxFractionDigits)
  }

  func fullString(units: KWEthereumUnit) -> String {
    return self.string(units: units, maxFractionDigits: 9)
  }

  func fullString(decimals: Int) -> String {
    return self.string(decimals: decimals, maxFractionDigits: 9)
  }

  var hexEncoded: String {
    return "0x" + String(self, radix: 16)
  }
}
