//
//  SwapViewController.swift
//  KPTestFramework
//
//  Created by Manh Le on 22/11/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import KyberWidget
import QRCodeReaderViewController

class SwapViewController: UIViewController {

  @IBOutlet weak var commisionIDTextField: UITextField!
  @IBOutlet weak var signerTextField: UITextField!
  @IBOutlet weak var pinnedTokenTextField: UITextField!
  @IBOutlet weak var defaultPairTextField: UITextField!

  @IBOutlet weak var networkSegment: UISegmentedControl!
  @IBOutlet weak var continueButton: UIButton!

  // 0: signer, 1: commistionID
  fileprivate var scanDataType: Int = 0
  fileprivate var coordinator: KWCoordinator?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.continueButton.rounded(radius: 4.0)
  }

  @IBAction func scanSignerPressed(_ sender: Any) {
    self.scanDataType = 0
    self.openReader()
  }

  @IBAction func scanCommissionPressed(_ sender: Any) {
    self.scanDataType = 1
    self.openReader()
  }

  @IBAction func continueButtonPressed(_ sender: Any) {
    let network: KWEnvironment = {
      if networkSegment.selectedSegmentIndex == 0 { return .ropsten }
      if networkSegment.selectedSegmentIndex == 1 { return .rinkeby }
      return .production
    }()
    let pinnedToken = self.pinnedTokenTextField.text ?? ""
    let defaultPair = self.defaultPairTextField.text ?? "ETH_KNC"
    let signer = self.signerTextField.text ?? ""
    let commissionID = self.commisionIDTextField.text ?? ""
    do {
      self.coordinator = try KWSwapCoordinator(
        baseViewController: self,
        pinnedTokens: pinnedToken,
        defaultPair: defaultPair.isEmpty ? "ETH_KNC" : defaultPair,
        network: network,
        signer: signer.isEmpty ? nil : signer,
        commissionId: commissionID.isEmpty ? nil : commissionID
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

extension SwapViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      switch self.scanDataType {
      case 0: self.signerTextField.text = result
      case 1: self.commisionIDTextField.text = result
      default: break
      }
    }
  }
}

extension SwapViewController: KWCoordinatorDelegate {
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
        case .invalidPinnedToken(let errorMessage):
          return errorMessage
        case .invalidSignerAddress(let errorMessage):
          return errorMessage
        case .invalidCommisionAddress(let errorMessage):
          return errorMessage
        case .invalidProductAvatarURL(let errorMessage):
          return errorMessage
        }
      }()
      self.showAlertController(title: "Failed", message: errorMessage)
      self.coordinator = nil
    })
  }

  func coordinatorDidBroadcastTransaction(with hash: String) {
    self.coordinator?.stop(completion: {
      self.showAlertController(title: "Swap transaction sent", message: "Tx hash: \(hash)")
      self.coordinator = nil
    })
  }
}



