//
//  UIButton+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

extension UIButton {

  func setBackgroundColor(_ color: UIColor, forState: UIControlState) {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
    UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let colorImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    self.setBackgroundImage(colorImage, for: forState)
  }

  func setImage(
    with url: URL,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.setImage(image.resizeImage(to: size), for: .normal)
        }
      }
    }.resume()
  }

  func setImage(
    with string: String,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    guard let url = URL(string: string) else { return }
    self.setImage(
      with: url,
      placeHolder: placeHolder,
      size: size,
      state: state
    )
  }

  func centerVertically(padding: CGFloat = 6.0) {
    guard
      let imageViewSize = self.imageView?.frame.size,
      let titleLabelSize = self.titleLabel?.frame.size else {
        return
    }

    let totalHeight = imageViewSize.height + titleLabelSize.height + padding

    self.imageEdgeInsets = UIEdgeInsets(
      top: -(totalHeight - imageViewSize.height),
      left: 0.0,
      bottom: 0.0,
      right: -titleLabelSize.width
    )

    self.titleEdgeInsets = UIEdgeInsets(
      top: 0.0,
      left: -imageViewSize.width,
      bottom: -(totalHeight - titleLabelSize.height),
      right: 0.0
    )

    self.contentEdgeInsets = UIEdgeInsets(
      top: (self.frame.height - totalHeight) / 2.0,
      left: 0.0,
      bottom: titleLabelSize.height,
      right: 0.0
    )
  }

  func setTokenImage(
    token: KWTokenObject,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    if let image = UIImage(named: token.icon.lowercased(), in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil) {
      self.setImage(image.resizeImage(to: size), for: .normal)
    } else {
      let placeHolderImg = UIImage(named: "default_token", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil)
      self.setImage(
        with: token.iconURL,
        placeHolder: placeHolderImg,
        size: size,
        state: state
      )
    }
  }
}
