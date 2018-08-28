//
//  KWStepView.swift
//  KyberPayiOS
//
//  Created by Manh Le on 22/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit

enum KWStepViewState: Int {
  case chooseToken = 0
  case importAddress = 1
  case confirm = 2
}

class KWStepView: KWXibLoaderView {

  let backgroudColors: [UIColor] = [
    KWThemeConfig.current.inactiveBackgroundColor,
    KWThemeConfig.current.activeStepBackgroundColor,
  ]

  let textColors: [UIColor] = [
    KWThemeConfig.current.inactiveBackgroundColor,
    KWThemeConfig.current.activeStepBackgroundColor,
  ]

  let images: [UIImage?] = [
    nil,
    KWThemeConfig.current.doneIcon,
  ]

  @IBOutlet weak var paymentStepImageView: UIImageView!
  @IBOutlet weak var firstSeparatorView: UIView!
  @IBOutlet weak var paymentLabel: UILabel!
  
  @IBOutlet weak var importWalletImageView: UIImageView!
  @IBOutlet var secondSeparatorView: UIView!
  @IBOutlet weak var importLabel: UILabel!
  
  @IBOutlet weak var confirmImageView: UIImageView!
  @IBOutlet weak var confirmLabel: UILabel!

  override func commonInit() {
    super.commonInit()
    self.paymentStepImageView.rounded(radius: self.paymentStepImageView.frame.height / 2.0)
    self.importWalletImageView.rounded(radius: self.importWalletImageView.frame.height / 2.0)
    self.confirmImageView.rounded(radius: self.confirmImageView.frame.height / 2.0)
    self.paymentStepImageView.backgroundColor = KWThemeConfig.current.inactiveBackgroundColor
    self.importWalletImageView.backgroundColor = KWThemeConfig.current.inactiveBackgroundColor
    self.confirmImageView.backgroundColor = KWThemeConfig.current.inactiveBackgroundColor

    self.paymentLabel.text = KWStringConfig.current.payment
    self.importLabel.text = KWStringConfig.current.importWallet
    self.confirmLabel.text = KWStringConfig.current.confirm
  }

  func updateView(with state: KWStepViewState, isPayment: Bool) {
    let paymentState: Int = 1
    let importState: Int = state == .chooseToken ? 0 : 1
    let confirmState: Int = state == .confirm ? 1 : 0

    self.paymentLabel.text = isPayment ? KWStringConfig.current.payment : KWStringConfig.current.swap

    self.updateChooseToken(stateID: paymentState)
    self.updateImportWallet(stateID: importState)
    self.updateConfirm(stateID: confirmState)
  }

  /*
   3 states: inactive, active corresponding to 0, 1
   */
  fileprivate func updateChooseToken(stateID: Int) {
    self.paymentStepImageView.image = self.images[stateID]
    self.paymentStepImageView.backgroundColor = self.backgroudColors[stateID]
    self.paymentLabel.textColor = self.textColors[stateID]
    self.paymentStepImageView.rounded(
      color: .clear,
      width: 0.0,
      radius: self.paymentStepImageView.frame.height / 2.0
    )
  }

  fileprivate func updateImportWallet(stateID: Int) {
    self.importWalletImageView.image = self.images[stateID]
    self.importWalletImageView.backgroundColor = self.backgroudColors[stateID]
    self.importLabel.textColor = self.textColors[stateID]
    self.firstSeparatorView.backgroundColor = stateID == 0 ? KWThemeConfig.current.inactiveBackgroundColor : KWThemeConfig.current.activeStepBackgroundColor
    self.importWalletImageView.rounded(
      color: .clear,
      width: 0.0,
      radius: self.importWalletImageView.frame.height / 2.0
    )
  }

  fileprivate func updateConfirm(stateID: Int) {
    self.confirmImageView.image = self.images[stateID]
    self.confirmImageView.backgroundColor = self.backgroudColors[stateID]
    self.confirmLabel.textColor = self.textColors[stateID]
    self.secondSeparatorView.backgroundColor = stateID == 0 ? KWThemeConfig.current.inactiveBackgroundColor : KWThemeConfig.current.activeStepBackgroundColor
    self.confirmImageView.rounded(
      color: .clear,
      width: 0.0,
      radius: self.confirmImageView.frame.height / 2.0
    )
  }
}
