//
//  KWImportViewController.swift
//  KyberPayiOS
//
//  Created by Manh Le on 16/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import TrustCore
import TrustKeystore
import QRCodeReaderViewController

public enum KWImportViewEvent {
  case back
  case failed(errorMessage: String)
  case successImported(account: Account)
}

public protocol KWImportViewControllerDelegate: class {
  func importViewController(_ controller: KWImportViewController, run event: KWImportViewEvent)
}

public class KWImportViewController: UIViewController {

  fileprivate var viewModel: KWImportViewModel
  @IBOutlet weak var stepView: KWStepView!
  @IBOutlet weak var jsonButton: UIButton!
  @IBOutlet weak var privateKeyButton: UIButton!
  @IBOutlet weak var seedsButton: UIButton!

  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var underlineView: UIView!
  @IBOutlet weak var importJSONButton: UIButton!
  @IBOutlet weak var actionButton: UIButton!

  @IBOutlet weak var accountDetailsView: UIView!
  @IBOutlet weak var balanceLoadingIndicatorView: UIActivityIndicatorView!
  @IBOutlet weak var accountBalanceLabel: UILabel!
  @IBOutlet weak var accountAddressLabel: UILabel!
  @IBOutlet weak var changeWalletButton: UIButton!

  weak var delegate: KWImportViewControllerDelegate?

  fileprivate var loadingTimer: Timer?

  public init(viewModel: KWImportViewModel, delegate: KWImportViewControllerDelegate?) {
    self.viewModel = viewModel
    self.delegate = delegate
    super.init(nibName: "KWImportViewController", bundle: Bundle(identifier: "manhlx.kyber.network.KyberWidget"))
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationItem.title = KWStringConfig.current.importWallet
    // Start loading balance if needed
    self.startLoadBalanceTimer()
  }

  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.stopLoadingBalanceTimer()
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.jsonButton.centerVertically(padding: 10)
    self.privateKeyButton.centerVertically(padding: 10)
    self.seedsButton.centerVertically(padding: 10)
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupStepView()
    self.setupImportTypeButtons()
    self.setupElements()
  }

  fileprivate func setupNavigationBar() {
    let image = UIImage(named: "back_white_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor

    let qrcodeImage = UIImage(named: "qrcode_white_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil)
    let rightItem = UIBarButtonItem(image: qrcodeImage, style: .plain, target: self, action: #selector(self.scanQRCodePressed(_:)))
    self.navigationItem.rightBarButtonItem = rightItem
    self.navigationItem.rightBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor
  }

  fileprivate func setupStepView() {
    self.stepView.updateView(with: .importAddress, isPayment: self.viewModel.dataType == .payment)
  }

  fileprivate func setupImportTypeButtons() {
    self.viewModel.updateSelectedType(0)
    self.jsonButton.rounded(radius: 10.0)
    self.jsonButton.setBackgroundColor(
      KWThemeConfig.current.importTypeButtonColor,
      forState: .selected
    )
    self.jsonButton.setBackgroundColor(UIColor.white, forState: .normal)
    self.jsonButton.setImage(UIImage(named: "json_import_select_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .selected)
    self.jsonButton.setImage(UIImage(named: "json_import_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .normal)
    self.jsonButton.setTitleColor(UIColor.white, for: .selected)
    self.jsonButton.setTitleColor(
      UIColor(red: 46, green: 57, blue: 87),
      for: .normal
    )
    self.jsonButton.centerVertically(padding: 10)

    self.privateKeyButton.rounded(radius: 10.0)
    self.privateKeyButton.setTitle(KWStringConfig.current.privateKey, for: .normal)
    self.privateKeyButton.setBackgroundColor(
      KWThemeConfig.current.importTypeButtonColor,
      forState: .selected
    )
    self.privateKeyButton.setImage(UIImage(named: "private_key_import_select_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .selected)
    self.privateKeyButton.setImage(UIImage(named: "private_key_import_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .normal)
    self.privateKeyButton.setBackgroundColor(UIColor.white, forState: .normal)
    self.privateKeyButton.setTitleColor(UIColor.white, for: .selected)
    self.privateKeyButton.setTitleColor(
      UIColor(red: 46, green: 57, blue: 87),
      for: .normal
    )
    self.privateKeyButton.centerVertically(padding: 10)

    self.seedsButton.rounded(radius: 10.0)
    self.seedsButton.setTitle(KWStringConfig.current.seeds, for: .normal)
    self.seedsButton.setBackgroundColor(
      KWThemeConfig.current.importTypeButtonColor,
      forState: .selected
    )
    self.seedsButton.setImage(UIImage(named: "seeds_import_select_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .selected)
    self.seedsButton.setImage(UIImage(named: "seeds_import_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil), for: .normal)
    self.seedsButton.setBackgroundColor(UIColor.white, forState: .normal)
    self.seedsButton.setTitleColor(UIColor.white, for: .selected)
    self.seedsButton.setTitleColor(
      UIColor(red: 46, green: 57, blue: 87),
      for: .normal
    )
    self.seedsButton.centerVertically(padding: 10)

    self.updateUIImportType(id: 0)
  }

  fileprivate func setupElements() {
    self.textField.delegate = self
    self.importJSONButton.isHidden = self.viewModel.isImportJSONButtonHidden
    self.importJSONButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.importJSONButton.setTitle(
      KWStringConfig.current.importYourJSONFile,
      for: .normal
    )
    self.actionButton.rounded(radius: 4.0)
    self.actionButton.setTitle(self.viewModel.actionButtonTitle, for: .normal)
    self.actionButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonNormalBackgroundColor,
      forState: .normal
    )
    self.actionButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonDisableBackgroundColor,
      forState: .disabled
    )
    self.actionButton.setTitleColor(
      KWThemeConfig.current.importButtonTitleColor,
      for: .normal
    )
    self.changeWalletButton.setTitle(KWStringConfig.current.changeWallet, for: .normal)

    self.importJSONButton.isHidden = self.viewModel.isImportJSONButtonHidden
    self.textField.isHidden = self.viewModel.hasAccount
    self.underlineView.isHidden = self.viewModel.hasAccount
    self.accountDetailsView.isHidden = !self.viewModel.hasAccount

    self.balanceLoadingIndicatorView.isHidden = self.viewModel.balance != nil
    if self.balanceLoadingIndicatorView.isHidden {
      self.balanceLoadingIndicatorView.stopAnimating()
    } else {
      self.balanceLoadingIndicatorView.startAnimating()
    }
    self.accountBalanceLabel.attributedText = self.viewModel.displayBalanceAttributedString
    self.accountAddressLabel.text = self.viewModel.displaySrcAddress

    self.accountBalanceLabel.isHidden = self.viewModel.balance == nil

    self.updateActionButton()
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.viewModel.removeWallets {
      self.delegate?.importViewController(self, run: .back)
    }
  }

  @IBAction func importJSONButtonPressed(_ sender: Any) {
    let controller: UIDocumentPickerViewController = {
      let types = ["public.text", "public.content", "public.item", "public.data"]
      let vc = UIDocumentPickerViewController(
        documentTypes: types,
        in: .import
      )
      vc.delegate = self
      vc.modalPresentationStyle = .formSheet
      return vc
    }()
    self.present(controller, animated: true, completion: nil)
  }

  @IBAction func jsonButtonPressed(_ sender: Any) {
    if self.viewModel.hasAccount {
      self.openAlertViewChangeWallet(
        title: "Change wallet?",
        message: "Do you want to use another wallet?"
      )
      return
    }
    self.updateUIImportType(id: 0)
  }

  @IBAction func privateKeyButtonPressed(_ sender: Any) {
    if self.viewModel.hasAccount {
      self.openAlertViewChangeWallet(
        title: "Change wallet?",
        message: "Do you want to use another wallet?"
      )
      return
    }
    self.updateUIImportType(id: 1)
  }

  @IBAction func seedsButtonPressed(_ sender: Any) {
    if self.viewModel.hasAccount {
      self.openAlertViewChangeWallet(
        title: "Change wallet?",
        message: "Do you want to use another wallet?"
      )
      return
    }
    self.updateUIImportType(id: 2)
  }

  @IBAction func changeWalletButtonPressed(_ sender: Any) {
    self.displayLoading(text: "Remove wallet...", animated: true)
    self.viewModel.removeWallets {
      self.hideLoading()
      self.updateUIs()
    }
  }

  fileprivate func updateUIImportType(id: Int) {
    self.viewModel.updateSelectedType(id)
    self.updateUIs()
  }

  fileprivate func updateUIs() {
    UIView.animate(withDuration: 0.2) {
      self.jsonButton.isSelected = false
      self.privateKeyButton.isSelected = false
      self.seedsButton.isSelected = false
      if self.viewModel.selectedType == 0 {
        self.jsonButton.isSelected = true
        self.textField.placeholder = KWStringConfig.current.enterPasswordDescrypt
        self.textField.text = ""
      } else if self.viewModel.selectedType == 1 {
        self.privateKeyButton.isSelected = true
        self.textField.placeholder =
          KWStringConfig.current.enterPrivateKey
        self.textField.text = ""
      } else {
        self.seedsButton.isSelected = true
        self.textField.placeholder = KWStringConfig.current.enterSeeds
        self.textField.text = ""
      }
      self.importJSONButton.isHidden = self.viewModel.isImportJSONButtonHidden
      self.textField.isHidden = self.viewModel.hasAccount
      self.underlineView.isHidden = self.viewModel.hasAccount
      self.accountDetailsView.isHidden = !self.viewModel.hasAccount
      self.accountBalanceLabel.attributedText = self.viewModel.displayBalanceAttributedString
      self.accountAddressLabel.text = self.viewModel.displaySrcAddress

      self.updateActionButton()
    }
  }

  @objc func scanQRCodePressed(_ sender: Any) {
    let reader = QRCodeReaderViewController()
    reader.delegate = self
    self.present(reader, animated: true, completion: nil)
  }

  @IBAction func actionButtonPressed(_ sender: Any) {
    if self.viewModel.hasAccount {
      // Click Next button when imported a wallet
      self.checkDataBeforeConfirming()
      return
    }
    if self.viewModel.selectedType == 0 {
      // import json
      let keystore = self.viewModel.jsonData
      let password = self.textField.text ?? ""
      if keystore.isEmpty || password.isEmpty {
        self.showAlertController(title: "Invalid data", message: "Please check your input again")
        return
      }
      self.importWallet(type: .keystore(string: keystore, password: password))
    } else if self.viewModel.selectedType == 1 {
      let privateKey = self.textField.text ?? ""
      if privateKey.isEmpty {
        self.showAlertController(title: "Invalid data", message: "Please check your input again")
        return
      }
      self.importWallet(type: .privateKey(string: privateKey))
    } else {
      var seeds = self.textField.text ?? ""
      seeds = seeds.trimmingCharacters(in: .whitespacesAndNewlines)
      var words = seeds.components(separatedBy: " ").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines ) })
      words = words.filter({ !$0.replacingOccurrences(of: " ", with: "").isEmpty })
      if words.count != 12 {
        self.showAlertController(title: "Invalid data", message: "Must be 12 words")
        return
      }
      self.importWallet(type: .mnemonic(words: words, password: ""))
    }
  }

  fileprivate func updateActionButton() {
    self.actionButton.setTitle(self.viewModel.actionButtonTitle, for: .normal)
    if self.viewModel.hasAccount {
      self.actionButton.isEnabled = true
      return
    }
    let enabled: Bool = {
      if self.viewModel.selectedType == 0 {
        // json
        return !self.viewModel.jsonData.isEmpty && !(self.textField.text ?? "").isEmpty
      }
      if self.viewModel.selectedType == 1 {
        // private key
        return !(self.textField.text ?? "").isEmpty
      }
      if self.viewModel.selectedType == 2 {
        return !(self.textField.text ?? "").isEmpty
      }
      return false
    }()
    self.actionButton.isEnabled = enabled
  }

  fileprivate func importWallet(type: KWImportType) {
    self.displayLoading(text: "Importing...", animated: true)
    self.viewModel.clearWallets {
      self.viewModel.importWallet(importType: type, completion: { result in
        self.hideLoading()
        switch result {
        case .success:
          self.updateUIs()
          self.startLoadBalanceTimer()
        case .failure(let error):
          self.showAlertController(title: "Fail", message: error.localizedDescription)
        }
      })
    }
  }

  fileprivate func checkDataBeforeConfirming() {
    guard let account = self.viewModel.account else {
      self.showAlertController(
        title: "Account not found?",
        message: "Please import your account first"
      )
      self.updateUIs()
      return
    }
    if !self.viewModel.isBalanceEnough {
      self.openAlertViewChangeWallet(
        title: "Insufficient balance",
        message: "Your balance is not enough to make the transaction."
      )
      return
    }
    self.delegate?.importViewController(self, run: .successImported(account: account))
  }

  fileprivate func openAlertViewChangeWallet(title: String, message: String) {
    let alert = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Change Wallet", style: .default, handler: { action in
      self.changeWalletButtonPressed(action)
    }))
    self.present(alert, animated: true, completion: nil)
  }

  fileprivate func startLoadBalanceTimer() {
    self.stopLoadingBalanceTimer()
    self.loadBalance()
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
      self?.loadBalance()
    })
  }

  fileprivate func stopLoadingBalanceTimer() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  fileprivate func loadBalance() {
    if !self.viewModel.hasAccount {
      self.stopLoadingBalanceTimer()
      return
    }
    self.viewModel.getBalance {
      self.accountBalanceLabel.attributedText = self.viewModel.displayBalanceAttributedString
      self.accountBalanceLabel.isHidden = self.viewModel.balance == nil
      self.balanceLoadingIndicatorView.isHidden = self.viewModel.balance != nil
      if self.balanceLoadingIndicatorView.isHidden {
        self.balanceLoadingIndicatorView.stopAnimating()
      } else {
        self.balanceLoadingIndicatorView.startAnimating()
      }
    }
  }
}

extension KWImportViewController: QRCodeReaderDelegate {
  public func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  public func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.textField.text = result
      self.updateActionButton()
    }
  }
}

extension KWImportViewController: UITextFieldDelegate {
  public func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.updateActionButton()
    return false
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.updateActionButton()
    return false
  }
}

extension KWImportViewController: UIDocumentPickerDelegate {
  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    if controller.documentPickerMode == UIDocumentPickerMode.import {
      if let text = try? String(contentsOfFile: url.path) {
        self.viewModel.updateJSONData(text)
        self.updateActionButton()
        let name = url.lastPathComponent
        UIView.transition(
          with: self.importJSONButton,
          duration: 0.32,
          options: .transitionFlipFromTop,
          animations: {
            self.importJSONButton.setTitle(name, for: .normal)
        }, completion: nil
        )
      } else {
        self.showAlertController(title: "Invalid file", message: "Can not get data from file")
      }
    }
  }
}

