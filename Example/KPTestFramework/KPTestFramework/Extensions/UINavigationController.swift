//
//  UINavigationController.swift
//  KPTestFramework
//
//  Created by Manh Le on 17/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
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

  public func applyStyle() {
    navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationBar.isTranslucent = false
    navigationBar.shadowImage = UIImage()
    navigationBar.barTintColor = UIColor(red: 15.0/255.0, green: 170.0/255.0, blue: 162.0/255.0, alpha: 1.0)
    navigationBar.barStyle = UIBarStyle.black
    navigationBar.tintColor = UIColor.white
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
  }
}
