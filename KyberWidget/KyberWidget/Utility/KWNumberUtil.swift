//
//  KWNumberUtil.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import BigInt

final public class KWNumberUtil {

  static let shared = KWNumberUtil()

  var minimumFractionDigits = 0
  var maximumFractionDigits = 9

  var decimalSeparator = "."
  var groupingSeparator = ","

  init(locale: Locale = .current) {
    decimalSeparator = locale.decimalSeparator ?? "."
    groupingSeparator = locale.groupingSeparator ?? ","
  }

  /*
   Convert a string to a BigInt, given string and the units
   */
  func number(from string: String, units: KWEthereumUnit = .ether) -> BigInt? {
    let decimals = Int(log10(Double(units.rawValue)))
    return self.number(from: string, decimals: decimals)
  }

  /*
   Convert a string to a BigInt, given a string and decimals
   */
  func number(from string: String, decimals: Int) -> BigInt? {
    guard let index = string.index(where: { String($0) == self.decimalSeparator }) else {
      return BigInt(string).flatMap({ $0 * BigInt(10).power(decimals) })
    }
    var fullString = string
    fullString.remove(at: index)

    let fractionalDigits = string.distance(from: string.index(after: index), to: string.endIndex)
    if fractionalDigits > decimals {
      // Can not present accurate, remove last some fraction digits
      fullString.removeLast(fractionalDigits - decimals)
    }
    guard let number = BigInt(fullString) else { return nil }
    return number * BigInt(10).power(max(0, decimals - fractionalDigits))
  }

  /*
   Return string presentation of a BigInt
   */
  func string(from number: BigInt, units: KWEthereumUnit = .ether) -> String {
    let decimals = Int(log10(Double(units.rawValue)))
    return self.string(from: number, decimals: decimals)
  }

  func string(from number: BigInt, decimals: Int) -> String {
    let dividend = BigInt(10).power(decimals)
    let (integerPart, remainder) = number.quotientAndRemainder(dividingBy: dividend)
    let integerString = self.integerString(from: integerPart)
    let fractionalString = self.fractionalString(from: BigInt(sign: .plus, magnitude: remainder.magnitude), decimals: decimals)
    if fractionalString.isEmpty { return integerString }
    return "\(integerString).\(fractionalString)"
  }

  fileprivate func integerString(from: BigInt) -> String {
    var string = from.description
    let end = from.sign == .minus ? 1 : 0
    for offset in stride(from: string.count - 3, to: end, by: -3) {
      let index = string.index(string.startIndex, offsetBy: offset)
      string.insert(contentsOf: groupingSeparator, at: index)
    }
    return string
  }

  fileprivate func fractionalString(from number: BigInt, decimals: Int) -> String {
    let counts = number.description.count
    var num = number

    if num == 0 || decimals - counts > maximumFractionDigits {
      return String(repeating: "0", count: minimumFractionDigits)
    }

    if decimals < minimumFractionDigits {
      num *= BigInt(10).power(minimumFractionDigits - decimals)
    }
  
    if decimals > maximumFractionDigits {
      num /= BigInt(10).power(decimals - maximumFractionDigits)
    }

    var string = num.description
    if counts < decimals {
      string = String(repeating: "0", count: decimals - counts) + string
    }

    // Remove extra zeros after the decimal point
    if let lastNonZeroIndex = string.reversed().index(where: { $0 != "0" })?.base {
      let zeros = string.distance(from: string.startIndex, to: lastNonZeroIndex)
      if zeros > minimumFractionDigits {
        let newEndIndex = string.index(string.startIndex, offsetBy: zeros - minimumFractionDigits)
        string = String(string[string.startIndex..<newEndIndex])
      }
    }

    return string
  }
}
