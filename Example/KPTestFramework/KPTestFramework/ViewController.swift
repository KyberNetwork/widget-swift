//
//  ViewController.swift
//  KPTestFramework
//
//  Created by Manh Le on 22/11/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var payButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!
  @IBOutlet weak var buyButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.payButton.rounded(radius: 4.0)
    self.swapButton.rounded(radius: 4.0)
    self.buyButton.rounded(radius: 4.0)
  }

  @IBAction func payButtonPressed(_ sender: Any) {
    self.navigationController?.pushViewController(PayViewController(), animated: true)
  }

  @IBAction func swapButtonPressed(_ sender: Any) {
    self.navigationController?.pushViewController(SwapViewController(), animated: true)
  }

  @IBAction func buyButtonPressed(_ sender: Any) {
    self.navigationController?.pushViewController(BuyViewController(), animated: true)
  }
}

extension UIView {
  func rounded(radius: CGFloat) {
    self.layer.borderWidth = 0.0
    self.layer.borderColor = UIColor.clear.cgColor
    self.layer.cornerRadius = radius
    self.clipsToBounds = true
  }
}
