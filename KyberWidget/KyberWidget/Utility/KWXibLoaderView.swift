//
//  KWXibLoaderView.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

class KWXibLoaderView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.commonInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.commonInit()
  }

  func commonInit() {
    self.backgroundColor = .clear

    let bundle = Bundle(identifier: "manhlx.kyber.network.KyberWidget")
    let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    view.frame = self.bounds
    self.addSubview(view)
    view.boundInside(self)
  }
}
