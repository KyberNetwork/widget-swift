//
//  UIViewController.swift
//  KPTestFramework
//
//  Created by Manh Le on 17/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit

extension UIViewController {
  func showAlertController(title: String, message: String) {
    let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(controller, animated: true, completion: nil)
  }
}
