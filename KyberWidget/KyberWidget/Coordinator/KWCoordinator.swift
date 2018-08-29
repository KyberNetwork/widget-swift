//
//  KWCoordinator.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt
import Result
import TrustKeystore
import TrustCore

public enum KWError {
  case unsupportedToken
  case invalidAddress(errorMessage: String)
  case invalidToken(errorMessage: String)
  case invalidAmount(errorMessage: String)
  case failedToLoadSupportedToken(errorMessage: String)
  case failedToSendPayment(errorMessage: String)
}

public protocol KWCoordinatorDelegate: class {
  func coordinatorDidCancel()
  func coordinatorDidFailed(with error: KWError)
  func coordinatorDidBroadcastTransaction(with hash: String)
}

public enum KWDataType {
  case pay
  case swap
  case buy
}

// Use these 3 subclasses to initialize only
public class KWPayCoordinator: KWCoordinator {
  public init(
    baseViewController: UIViewController,
    receiveAddr: String,
    receiveToken: String,
    receiveAmount: Double?,
    network: KWEnvironment = .ropsten,
    signer: String? = nil,
    commissionId: String? = nil,
    productName: String,
    productAvatar: String
    ) throws {
    try super.init(
      baseViewController: baseViewController,
      receiveAddr: receiveAddr,
      receiveToken: receiveToken,
      receiveAmount: receiveAmount,
      type: .pay,
      network: network,
      signer: signer,
      commissionId: commissionId,
      productName: productName,
      productAvatar: productAvatar
    )
  }
}

public class KWSwapCoordinator: KWCoordinator {
  public init(
    baseViewController: UIViewController,
    network: KWEnvironment = .ropsten,
    signer: String? = nil,
    commissionId: String? = nil,
    productName: String,
    productAvatar: String
    ) throws {
    try super.init(
      baseViewController: baseViewController,
      receiveAddr: "",
      receiveToken: nil,
      receiveAmount: nil,
      type: .swap,
      network: network,
      signer: signer,
      commissionId: commissionId,
      productName: productName,
      productAvatar: productAvatar
    )
  }
}

public class KWBuyCoordinator: KWCoordinator {
  public init(
    baseViewController: UIViewController,
    receiveToken: String,
    receiveAmount: Double?,
    network: KWEnvironment,
    signer: String?,
    commissionId: String?,
    productName: String,
    productAvatar: String
    ) throws {
    try super.init(
      baseViewController: baseViewController,
      receiveAddr: "",
      receiveToken: receiveToken,
      receiveAmount: receiveAmount,
      type: .buy,
      network: network,
      signer: signer,
      commissionId: commissionId,
      productName: productName,
      productAvatar: productAvatar
    )
  }
}

public class KWCoordinator {

  let baseViewController: UIViewController
  let navigationController: UINavigationController
  let receiverAddress: String
  let receiverTokenSymbol: String
  var receiverToken: KWTokenObject? = nil
  let receiverTokenAmount: Double?
  let dataType: KWDataType
  let productName: String
  let productAvatar: String

  let network: KWEnvironment

  var payment: KWPayment?

  let signer: String?
  let commissionId: String?

  fileprivate(set) var keystore: KWKeystore
  fileprivate(set) var account: Account?
  fileprivate(set) var tokens: [KWTokenObject] = []

  public weak var delegate: KWCoordinatorDelegate?

  lazy var provider: KWExternalProvider = {
    return KWExternalProvider(keystore: keystore, network: network)
  }()

  fileprivate var paymentMethodVC: KWPaymentMethodViewController!

  fileprivate var searchTokenVC: KWSearchTokenViewController?
  fileprivate var isSelectingSource: Bool = true
  fileprivate var importWalletVC: KWImportViewController?
  fileprivate var confirmVC: KWConfirmPaymentViewController?

  public init(
    baseViewController: UIViewController,
    receiveAddr: String,
    receiveToken: String?,
    receiveAmount: Double?,
    type: KWDataType,
    network: KWEnvironment,
    signer: String? = nil,
    commissionId: String? = nil,
    productName: String,
    productAvatar: String
    ) throws {
    self.baseViewController = baseViewController
    self.navigationController = {
      let navController = UINavigationController()
      navController.applyStyle(
        color: KWThemeConfig.current.navigationBarBackgroundColor,
        tintColor: KWThemeConfig.current.navigationBarTintColor
      )
      return navController
    }()
    self.receiverAddress = receiveAddr
    self.receiverTokenSymbol = receiveToken ?? ""

    if (receiveToken ?? "").isEmpty {
      // receive amount is ignored if receive token is empty
      self.receiverTokenAmount = nil
    } else {
      self.receiverTokenAmount = receiveAmount
    }
    self.network = network
    self.signer = signer
    self.commissionId = commissionId
    self.keystore = try KWKeystore()

    self.dataType = type
    self.productName = productName
    self.productAvatar = productAvatar
  }

  public func start(completion: (() -> Void)? = nil) {
    if self.receiverAddress != "" && Address(string: self.receiverAddress) == nil {
      let errorMessage: String = "Pass empty string if you want to swap or buy, otherwise receiver address must be a valid ETH addres"
      self.startSession(error: .invalidAddress(errorMessage: errorMessage), completion: completion)
      return
    }
    if self.dataType == .pay && self.receiverTokenSymbol.isEmpty {
      let errorMessage: String = "Needs to pass token symbol for payment transaction"
      self.startSession(error: .invalidToken(errorMessage: errorMessage), completion: completion)
      return
    }
    if self.dataType == .buy && self.receiverTokenSymbol.isEmpty {
      let errorMessage: String = "Buy must have receive token"
      self.startSession(error: .invalidToken(errorMessage: errorMessage), completion: completion)
      return
    }
    self.baseViewController.displayLoading(text: "Loading...", animated: true)
    self.loadSupportedTokensIfNeeded { [weak self] result in
      guard let `self` = self else { return }
      self.baseViewController.hideLoading()
      switch result {
      case .success(let tokens):
        self.tokens = tokens
        self.receiverToken = tokens.first(where: { $0.symbol == self.receiverTokenSymbol })
        let error: KWError? = {
          // token is empty, it must be kyberswap (already checked above)
          if self.receiverTokenSymbol.isEmpty { return nil }
          guard self.receiverToken != nil else {
            return .unsupportedToken
          }
          if let amount = self.receiverTokenAmount, amount <= 0.0 {
            return .invalidAmount(errorMessage: "Amount can not be zero or negative.")
          }
          return nil
        }()
        self.startSession(error: error, completion: completion)
      case .failure(let error):
        self.startSession(error: .failedToLoadSupportedToken(errorMessage: error.localizedDescription), completion: completion)
      }
    }
  }

  fileprivate func startSession(error: KWError?, completion: (() -> Void)? = nil) {
    if let err = error {
      let fakeVC = UIViewController()
      fakeVC.view.backgroundColor = .clear
      fakeVC.modalPresentationStyle = .overCurrentContext
      self.baseViewController.present(fakeVC, animated: true) {
        self.delegate?.coordinatorDidFailed(with: err)
        completion?()
      }
    } else {
      self.paymentMethodVC = {
        let viewModel = KWPaymentMethodViewModel(
          receiverAddress: self.receiverAddress,
          receiverToken: self.receiverToken,
          toAmount: self.receiverTokenAmount,
          network: self.network,
          dataType: self.dataType,
          tokens: self.tokens,
          keystore: self.keystore
        )
        let controller = KWPaymentMethodViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        return controller
      }()
      self.navigationController.viewControllers = [self.paymentMethodVC]
      self.baseViewController.present(self.navigationController, animated: true, completion: completion)
      self.paymentMethodVC.coordinatorUpdateSupportedTokens(self.tokens)
    }
  }

  public func stop(completion: (() -> Void)? = nil) {
    self.baseViewController.dismiss(animated: true, completion: completion)
  }

  fileprivate func loadSupportedTokensIfNeeded(completion: @escaping (Result<[KWTokenObject], AnyError>) -> Void) {
    if self.network != .mainnet && self.network != .production {
      // list suppported tokens only works for production, mainnet
      let supportedTokens = KWJSONLoadUtil.loadListSupportedTokensFromJSONFile(env: network)
      completion(.success(supportedTokens))
      return
    }
    KWSupportedToken.shared.fetchTrackerSupportedTokens(network: self.network, completion: completion)
  }
}

extension KWCoordinator: KWImportViewControllerDelegate {
  public func importViewController(_ controller: KWImportViewController, run event: KWImportViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .failed(let errorMessage):
      self.navigationController.showAlertController(title: "Error", message: errorMessage)
    case .successImported(let account):
      self.checkAccountWhitelistedAndOpenConfirmView(with: account)
    }
  }

  fileprivate func checkAccountWhitelistedAndOpenConfirmView(with account: Account) {
    // Documentation: https://github.com/KyberNetwork/KyberWidget
    let isWhitelisted: Bool = {
      guard let signer = self.signer else { return true }
      let addresses = signer.lowercased().components(separatedBy: "_")
      let address = account.address.description.lowercased()
      return addresses.contains(address)
    }()
    if isWhitelisted {
      guard let newPayment = self.payment?.newObject(with: account) else { return }
      self.openConfirmationView(payment: newPayment)
      return
    }
    // Not whitelisted
    let alertController = UIAlertController(
      title: "Not whitelisted!",
      message: "Your provider does not allow to pay with this address. Please try to use another account.",
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
      self.keystore.removeAllAccounts { }
    }))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func openConfirmationView(payment: KWPayment) {
    self.confirmVC = {
      let viewModel = KWConfirmPaymentViewModel(
        dataType: self.dataType,
        payment: payment,
        network: self.network,
        keystore: self.keystore
      )
      let controller = KWConfirmPaymentViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.confirmVC!, animated: true)
  }
}

extension KWCoordinator: KWSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KWSearchTokenViewController, run event: KWSearchTokenViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let token) = event {
        self.paymentMethodVC.coordinatorUpdatePayToken(token, isSource: self.isSelectingSource)
      }
    }
  }
}

extension KWCoordinator: KWPaymentMethodViewControllerDelegate {
  public func paymentMethodViewController(_ controller: KWPaymentMethodViewController, run event: KWPaymentMethodViewEvent) {
    switch event {
    case .close:
      self.delegate?.coordinatorDidCancel()
    case .searchToken(let token, let isSource):
      self.openSearchTokenView(token, isSource: isSource)
    case .next(let payment):
      self.openImportView(with: payment)
    }
  }

  fileprivate func openSearchTokenView(_ selectedToken: KWTokenObject, isSource: Bool) {
    self.isSelectingSource = isSource
    self.searchTokenVC = {
      let viewModel = KWSearchTokenViewModel(supportedTokens: self.tokens)
      let controller = KWSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.searchTokenVC!, animated: true)
  }

  fileprivate func openImportView(with payment: KWPayment) {
    self.payment = payment
    self.importWalletVC = {
      let viewModel = KWImportViewModel(
        dataType: self.dataType,
        network: self.network,
        signer: self.signer,
        commissionID: self.commissionId,
        keystore: self.keystore,
        tokens: self.tokens,
        payment: payment
      )
      let controller = KWImportViewController(viewModel: viewModel, delegate: self)
      controller.loadViewIfNeeded()
      return controller
    }()
    self.navigationController.pushViewController(self.importWalletVC!, animated: true)
  }
}

extension KWCoordinator: KWConfirmPaymentViewControllerDelegate {
  public func confirmPaymentViewController(_ controller: KWConfirmPaymentViewController, run event: KWConfirmPaymentViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .confirmPayment(let payment):
      self.navigationController.displayLoading(text: "Paying...", animated: true)
      self.sendPaymentRequest(payment: payment) { (isSuccess, message) in
        if isSuccess {
          self.delegate?.coordinatorDidBroadcastTransaction(with: message ?? "")
        } else {
          self.delegate?.coordinatorDidFailed(with: .failedToSendPayment(errorMessage: message ?? ""))
        }
      }
    }
  }

  func sendPaymentRequest(payment: KWPayment, completion: @escaping (Bool, String?) -> Void) {
    if payment.from == payment.to {
      print("Send payment transfer request")
      self.provider.transfer(transaction: payment) { result in
        switch result {
        case .success(let hash):
          print("Success sending payment request with hash: \(hash)")
          completion(true, hash)
        case .failure(let error):
          print("Failed sending payment request with error: \(error.description)")
          completion(false, error.description)
        }
      }
    } else {
      print("Send payment exchange request")
      self.sendApprovedRequestIfNeeded(payment: payment) { (isSuccess, string) in
        if isSuccess {
          self.provider.exchange(exchange: payment, completion: { result in
            switch result {
            case .success(let hash):
              print("Success sending payment request with hash: \(hash)")
              completion(true, hash)
            case .failure(let error):
              print("Failed sending payment request with error: \(error.description)")
              completion(false, error.description)
            }
          })
        } else {
          print("Failed sending payment request with error: \(string)")
          completion(false, string)
        }
      }
    }
  }

  fileprivate func sendApprovedRequestIfNeeded(payment: KWPayment, completion: @escaping (Bool, String) -> Void) {
    guard let account = payment.account else {
      completion(false, "Account not found")
      return
    }
    if payment.from.isETH {
      print("No need send approved")
      completion(true, "")
      return
    }
    self.provider.getAllowance(token: payment.from, address: account.address) { result in
      switch result {
      case .success(let isApproved):
        if isApproved {
          print("No need send approved")
          completion(true, "")
        } else {
          self.provider.sendApproveERC20Token(exchangeTransaction: payment, completion: { apprResult in
            switch apprResult {
            case .success:
              print("Send approved success")
              completion(true, "")
            case .failure(let error):
              print("Send approved failed: \(error.description)")
              completion(false, error.description)
            }
          })
        }
      case .failure(let error):
        print("Send approved failed: \(error.description)")
        completion(false, error.description)
      }
    }
  }
}
