//
//  UIViewController+Kyber.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import MBProgressHUD

extension UIViewController {
  func displayLoading(text: String = "Loading ...", animated: Bool = true) {
    let hud = MBProgressHUD.showAdded(to: self.view, animated: animated)
    hud.label.text = text
  }

  func hideLoading(animated: Bool = true) {
    MBProgressHUD.hide(for: view, animated: animated)
  }

  func showAlertController(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(controller, animated: true, completion: nil)
  }
}
