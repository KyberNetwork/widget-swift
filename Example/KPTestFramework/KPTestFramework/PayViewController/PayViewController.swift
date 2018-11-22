//
//  PayViewController.swift
//  KPTestFramework
//
//  Created by Manh Le on 22/11/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import QRCodeReaderViewController
import KyberWidget

class PayViewController: UIViewController {

  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var tokenTextField: UITextField!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var commisionIDTextField: UITextField!
  @IBOutlet weak var signerTextField: UITextField!
  @IBOutlet weak var productNameTextField: UITextField!
  @IBOutlet weak var productAvatarTextField: UITextField!
  @IBOutlet weak var pinnedTokenTextField: UITextField!

  @IBOutlet weak var networkSegment: UISegmentedControl!
  @IBOutlet weak var continueButton: UIButton!

  // 0: address, 1: signer, 2: commistionID, 3: product avatar
  fileprivate var scanDataType: Int = 0
  fileprivate var coordinator: KWCoordinator?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.continueButton.rounded(radius: 4.0)
  }

  @IBAction func scanAddressPressed(_ sender: Any) {
    self.scanDataType = 0
    self.openReader()
  }

  @IBAction func scanSignerPressed(_ sender: Any) {
    self.scanDataType = 1
    self.openReader()
  }

  @IBAction func scanCommissionPressed(_ sender: Any) {
    self.scanDataType = 2
    self.openReader()
  }

  @IBAction func scanAvatarPressed(_ sender: Any) {
    self.scanDataType = 3
    self.openReader()
  }

  @IBAction func continueButtonPressed(_ sender: Any) {
    let address = self.addressTextField.text ?? ""
    let token = self.tokenTextField.text ?? ""
    let amount = Double(self.amountTextField.text ?? "")
    let signer = self.signerTextField.text ?? ""
    let network: KWEnvironment = {
      if networkSegment.selectedSegmentIndex == 0 { return .ropsten }
      if networkSegment.selectedSegmentIndex == 1 { return .rinkeby }
      return .production
    }()
    let pinnedToken = self.pinnedTokenTextField.text ?? "ETH_KNC_DAI"
    let commissionID = self.commisionIDTextField.text
    let productName = self.productNameTextField.text ?? ""
    let productAvt = self.productAvatarTextField.text
    do {
      self.coordinator = try KWPayCoordinator(
        baseViewController: self,
        receiveAddr: address,
        receiveToken: token,
        receiveAmount: amount,
        pinnedTokens: pinnedToken,
        network: network,
        signer: signer.isEmpty ? nil : signer,
        commissionId: commissionID,
        productName: productName,
        productAvatar: productAvt,
        productAvatarImage: nil
      )
      self.coordinator?.delegate = self
      self.coordinator?.start()
    } catch {
      print("Can not init coordinator")
    }
  }

  fileprivate func openReader() {
    let reader = QRCodeReaderViewController()
    reader.delegate = self
    self.present(reader, animated: true, completion: nil)
  }
}

extension PayViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    switch self.scanDataType {
    case 0: self.addressTextField.text = result
    case 1: self.signerTextField.text = result
    case 2: self.commisionIDTextField.text = result
    case 3: self.productAvatarTextField.text = result
    default: break
    }
  }
}

extension PayViewController: KWCoordinatorDelegate {
  func coordinatorDidCancel() {
    self.coordinator?.stop(completion: {
      self.coordinator = nil
    })
  }

  func coordinatorDidFailed(with error: KWError) {
    self.coordinator?.stop(completion: {
      let errorMessage: String = {
        switch error {
        case .unsupportedToken: return "Unsupported Tokens"
        case .invalidAddress(let errorMessage):
          return errorMessage
        case .invalidToken(let errorMessage):
          return errorMessage
        case .invalidAmount: return "Invalid Amount"
        case .failedToLoadSupportedToken(let errorMessage):
          return errorMessage
        case .failedToSendTransaction(let errorMessage):
          return errorMessage
        case .invalidDefaultPair(let errorMessage):
          return errorMessage
        }
      }()
      self.showAlertController(title: "Failed", message: errorMessage)
      self.coordinator = nil
    })
  }

  func coordinatorDidBroadcastTransaction(with hash: String) {
    self.coordinator?.stop(completion: {
      self.showAlertController(title: "Payment sent", message: "Tx hash: \(hash)")
      self.coordinator = nil
    })
  }
}
