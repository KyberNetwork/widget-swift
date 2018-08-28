//
//  UINavigationController.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

extension UINavigationController {
  public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

  public func popViewController(animated: Bool, completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    popViewController(animated: animated)
    CATransaction.commit()
  }

  func applyStyle(color: UIColor = UIColor.Kyber.background, tintColor: UIColor = .white) {
    navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationBar.isTranslucent = false
    navigationBar.shadowImage = UIImage()
    navigationBar.barTintColor = color
    navigationBar.barStyle = UIBarStyle.black
    navigationBar.tintColor = tintColor
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
  }
}
