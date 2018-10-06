//
//  UIView+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import MBProgressHUD

extension UIView {

  func boundInside(_ superView: UIView) {
    self.translatesAutoresizingMaskIntoConstraints = false
    superView.addConstraints(NSLayoutConstraint.constraints(
      withVisualFormat: "H:|-0-[subview]-0-|",
      options: NSLayoutConstraint.FormatOptions(),
      metrics: nil,
      views: ["subview": self]
      )
    )
    superView.addConstraints(NSLayoutConstraint.constraints(
      withVisualFormat: "V:|-0-[subview]-0-|",
      options: NSLayoutConstraint.FormatOptions(),
      metrics: nil,
      views: ["subview": self]
      )
    )
  }

  func rounded(color: UIColor = .clear, width: CGFloat = 0.0, radius: CGFloat) {
    self.layer.borderColor = color.cgColor
    self.layer.borderWidth = width
    self.layer.cornerRadius = radius
    self.clipsToBounds = true
  }

  func removeSublayer(at index: Int) {
    guard let layers = self.layer.sublayers, layers.count > index else { return }
    layers[index].removeFromSuperlayer()
  }

  func toImage() -> UIImage? {
    let rect = self.bounds

    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    self.layer.render(in: context!)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }

  func addShadow(
    color: UIColor = UIColor(red: 12.0/255, green: 0, blue: 51.0/255, alpha: 0.1),
    offset: CGSize = CGSize(width: 1, height: 2),
    opacity: Float = 0.16,
    radius: CGFloat = 1
    ) {
    self.layer.shadowColor = color.cgColor
    self.layer.shadowOffset = offset
    self.layer.shadowOpacity = opacity
    self.layer.shadowRadius = radius
    self.layer.masksToBounds = false
    self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    self.layer.shouldRasterize = true
    self.layer.rasterizationScale = UIScreen.main.scale
  }

  func dashLine(width: CGFloat, color: UIColor) {
    let shapeLayer = CAShapeLayer()
    shapeLayer.strokeColor = color.cgColor
    shapeLayer.lineWidth = width
    shapeLayer.lineDashPattern = [7, 3] // 7: length of dash, 3: length of gap between

    let path = CGMutablePath()
    let start = CGPoint(x: 0, y: self.frame.height / 2.0)
    let end = CGPoint(x: self.frame.width, y: self.frame.height / 2.0)
    path.addLines(between: [start, end])
    shapeLayer.path = path
    self.removeSublayer(at: 0)
    self.layer.insertSublayer(shapeLayer, at: 0)
  }
}
