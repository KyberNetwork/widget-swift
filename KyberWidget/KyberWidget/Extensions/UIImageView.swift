//
//  UIImageView.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

extension UIImageView {

  func setImage(
    with url: URL,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.image = placeHolder?.resizeImage(to: size)
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.image = image.resizeImage(to: size)
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
    self.image = placeHolder?.resizeImage(to: size)
    guard let url = URL(string: string) else { return }
    self.setImage(
      with: url,
      placeHolder: placeHolder,
      size: size,
      state: state
    )
  }

  func setTokenImage(
    token: KWTokenObject,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    if let image = UIImage(named: token.icon.lowercased(), in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil) {
      self.image = image.resizeImage(to: size)
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
