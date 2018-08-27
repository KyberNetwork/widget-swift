//
//  Data.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

extension Data {

  var hex: String {
    return map { String(format: "%02hhx", $0) }.joined()
  }

  var hexEncoded: String {
    return "0x" + self.hex
  }

  init(hex: String) {
    let len = hex.count / 2
    var data = Data(capacity: len)
    for i in 0..<len {
      let from = hex.index(hex.startIndex, offsetBy: i*2)
      let to = hex.index(hex.startIndex, offsetBy: i*2 + 2)
      let bytes = hex[from ..< to]
      if var num = UInt8(bytes, radix: 16) {
        data.append(&num, count: 1)
      }
    }
    self = data
  }
}
