//
//  MainViewController.swift
//  KPTestFramework
//
//  Created by Manh Le on 18/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import QRCodeReaderViewController
import KyberWidget

class MainViewController: UIViewController {

  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var tokenSymbolTextField: UITextField!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var envSegmentedControl: UISegmentedControl!
  @IBOutlet weak var signerTextField: UITextField!
  @IBOutlet weak var commissionIDTextField: UITextField!
  @IBOutlet weak var flowTypeSegmentedControl: UISegmentedControl!

  var qrcodeID: Int = 0
  fileprivate var coordinator: KWCoordinator?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.continueButton.layer.cornerRadius = 4.0
    self.continueButton.clipsToBounds = true
    self.flowTypeSegmentedControlDidChange(self.flowTypeSegmentedControl)
  }
    
  @IBAction func continueButtonPressed(_ sender: Any) {
    let address = self.addressTextField.text ?? ""
    let symbol = self.tokenSymbolTextField.text
    let amount: Double? = {
      if let text = self.amountTextField.text, !text.isEmpty {
        return Double(text)
      }
      return nil
    }()
    let envID = self.envSegmentedControl.selectedSegmentIndex

    //    let string = KWStringConfig.current
    //    let config = KWThemeConfig.current
    let network: KWEnvironment = {
      if envID == 0 { return .ropsten }
      if envID == 1 { return .staging }
      return .production
    }()
    let signer: String? = {
      if let text = self.signerTextField.text, !text.isEmpty { return text }
      return nil
    }()
    let commissionID: String? = {
      if let text = self.commissionIDTextField.text, !text.isEmpty { return text }
      return nil
    }()
    do {
      if self.flowTypeSegmentedControl.selectedSegmentIndex == 0 {
        // Payment
        self.coordinator = try KWPaymentCoordinator(
          baseViewController: self,
          receiveAddr: address,
          receiveToken: symbol ?? "",
          receiveAmount: amount,
          network: network,
          signer: signer,
          commissionID: commissionID
        )
      } else {
        // Swap
        self.coordinator = try KWSwapCoordinator(
          baseViewController: self,
          receiveToken: symbol,
          network: network,
          signer: signer,
          commissionID: commissionID
        )
      }
      self.coordinator?.delegate = self
      self.coordinator?.start()
    } catch {
      print("Can not init coordinator")
    }
  }

  @IBAction func envSegmentedControlDidChange(_ sender: UISegmentedControl) {
  }

  @IBAction func addressToPayQRButtonPressed(_ sender: Any) {
    self.presentQRCode(with: 0)
  }

  @IBAction func signerQRButtonPressed(_ sender: Any) {
    self.presentQRCode(with: 1)
  }

  @IBAction func commissionQRButtonPressed(_ sender: Any) {
    self.presentQRCode(with: 2)
  }

  @IBAction func flowTypeSegmentedControlDidChange(_ sender: UISegmentedControl) {
    if sender.selectedSegmentIndex == 0 {
      // payment
      self.addressTextField.text = "0x63b42a7662538a1da732488c252433313396eade"
      self.addressTextField.isEnabled = true

      self.amountTextField.text = ""
      self.amountTextField.isEnabled = true
    } else {
      // swap
      self.addressTextField.text = "self"
      self.addressTextField.isEnabled = false

      self.amountTextField.text = ""
      self.amountTextField.isEnabled = false
    }
  }

  fileprivate func presentQRCode(with ID: Int) {
    self.qrcodeID = ID
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    self.present(qrcode, animated: true, completion: nil)
  }
}

extension MainViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      if self.qrcodeID == 0 {
        // address to pay
        self.addressTextField.text = result
      } else if self.qrcodeID == 1 {
        // signer
        self.signerTextField.text = result
      } else if self.qrcodeID == 2 {
        // commission ID
        self.commissionIDTextField.text = result
      }
    }
  }
}

extension MainViewController: KWCoordinatorDelegate {
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
        case .failedToSendPayment(let errorMessage):
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


