//
//  KWReceiveTokenViewController.swift
//  KyberWidget
//
//  Created by Manh Le on 7/10/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import MBProgressHUD

class KWReceiveTokenViewController: UIViewController {

  let wallet: String
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var walletLabel: UILabel!
  @IBOutlet weak var copyButton: UIButton!

  init(wallet: String) {
    self.wallet = wallet
    super.init(nibName: "KWReceiveTokenViewController", bundle: Bundle.framework)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupNavigationBar()
    self.setupWalletData()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = KWStringConfig.current.receive
    let image = UIImage(named: "back_white_icon", in: Bundle.framework, compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor
  }

  fileprivate func setupWalletData() {
    self.walletLabel.text = self.wallet
    self.copyButton.rounded(radius: 4.0)
    self.copyButton.setTitle(KWStringConfig.current.copy, for: .normal)
    self.copyButton.setBackgroundColor(KWThemeConfig.current.receiveCopyButtonColor, forState: .normal)

    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: self.wallet)
      DispatchQueue.main.async {
        self.imageView.image = image
        self.view.layoutIfNeeded()
      }
    }
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyButtonPressed(_ sender: Any) {
    UIPasteboard.general.string = self.wallet
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("address.copied", value: "Address copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }
}
