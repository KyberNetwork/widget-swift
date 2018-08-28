//
//  UIColor+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

extension UIColor {
  convenience init(hex: String) {
    let scanner = Scanner(string: hex)
    scanner.scanLocation = 0

    var rgbValue: UInt64 = 0

    scanner.scanHexInt64(&rgbValue)

    let r = (rgbValue & 0xff0000) >> 16
    let g = (rgbValue & 0xff00) >> 8
    let b = rgbValue & 0xff

    self.init(
      red: CGFloat(r) / 0xff,
      green: CGFloat(g) / 0xff,
      blue: CGFloat(b) / 0xff, alpha: 1
    )
  }

  convenience init(red: Int, green: Int, blue: Int) {
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }

  struct Kyber {
    static var shamrock = UIColor(red: 49, green: 203, blue: 158)
    static var background = UIColor(red: 15, green: 170, blue: 162)
    static var border = UIColor(red: 184, green: 186, blue: 190)
    static var action = UIColor(red: 30, green: 137, blue: 193)
    static var segment = UIColor(red: 158, green: 161, blue: 170)
    static var black = UIColor(red: 20, green: 25, blue: 39)
    static var grey = UIColor(red: 104, green: 116, blue: 143)
    static var minRate = UIColor(red: 46, green: 57, blue: 87)
    static var dashLine = UIColor(red: 186, green: 191, blue: 207)
  }
}
