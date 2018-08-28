//
//  String+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt

extension String {

  func removeGroupSeparator() -> String {
    return self.replacingOccurrences(of: KWNumberUtil.shared.groupingSeparator, with: "")
  }

  var hex: String {
    let data = self.data(using: .utf8)!
    return data.map { String(format: "%02x", $0) }.joined()
  }

  var hexEncoded: String {
    let data = self.data(using: .utf8)!
    return data.hexEncoded
  }

  func cleanStringToNumber() -> String {
    let decimals: Character = KWNumberUtil.shared.decimalSeparator.first!
    var valueString = ""
    var hasDecimals: Bool = false
    for char in self {
      if (char >= "0" && char <= "9") || (char == decimals && !hasDecimals) {
        valueString += "\(char)"
        if char == decimals { hasDecimals = true }
      }
    }
    return valueString
  }

  func toBigInt(decimals: Int) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * pow(10.0, Double(decimals)))
    }
    return KWNumberUtil.shared.number(
      from: self.removeGroupSeparator(),
      decimals: decimals
    )
  }

  func toBigInt(units: KWEthereumUnit) -> BigInt? {
    if let double = Double(self.removeGroupSeparator()) {
      return BigInt(double * Double(units.rawValue))
    }
    return KWNumberUtil.shared.number(
      from: self.removeGroupSeparator(),
      units: units
    )
  }

  var drop0x: String {
    if self.count > 2 && self.substring(with: 0..<2) == "0x" {
      return String(self.dropFirst(2))
    }
    return self
  }

  func index(from: Int) -> Index {
    return self.index(startIndex, offsetBy: from)
  }

  func substring(from: Int) -> String {
    let fromIndex = index(from: from)
    return String(self[fromIndex...])
  }

  func substring(to: Int) -> String {
    let toIndex = index(from: to)
    return String(self[..<toIndex])
  }

  func substring(with r: Range<Int>) -> String {
    let startIndex = index(from: r.lowerBound)
    let endIndex = index(from: r.upperBound)
    return String(self[startIndex..<endIndex])
  }
}
