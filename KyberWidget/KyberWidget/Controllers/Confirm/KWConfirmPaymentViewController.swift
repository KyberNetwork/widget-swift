//
//  KWConfirmPaymentViewController.swift
//  KyberPayiOS
//
//  Created by Manh Le on 22/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit

public enum KWConfirmPaymentViewEvent {
  case back
  case confirm(transaction: KWTransaction)
}

public protocol KWConfirmPaymentViewControllerDelegate: class {
  func confirmPaymentViewController(_ controller: KWConfirmPaymentViewController, run event: KWConfirmPaymentViewEvent)
}

public class KWConfirmPaymentViewController: UIViewController {

  @IBOutlet weak var stepView: KWStepView!

  @IBOutlet weak var transactionDetailsContainerView: UIView!
  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var fromValueLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var toValueLabel: UILabel!
  @IBOutlet weak var txDetailsSeparatorView: UIView!
  @IBOutlet weak var txDetailsTransactionFeeTextLabel: UILabel!
  @IBOutlet weak var txDetailsTransactionFeeValueLabel: UILabel!

  @IBOutlet weak var orderDetailsDataContainerView: UIView!
  @IBOutlet weak var orderDetailsTextLabel: UILabel!
  @IBOutlet weak var productNameLabel: UILabel!
  @IBOutlet weak var productAvatarImageView: UIImageView!
  @IBOutlet weak var productAvatarImageViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var orderAmountTextLabel: UILabel!
  @IBOutlet weak var orderAmountLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var transactionFeeValueLabel: UILabel!
  @IBOutlet weak var receiverAddressLabel: UILabel!

  @IBOutlet weak var transactionTypeTextLabel: UILabel!
  @IBOutlet weak var transactionTypeTopPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var firstAmountLabel: UILabel!
  @IBOutlet weak var secondAmountLabel: UILabel!

  @IBOutlet weak var yourWalletTextLabel: UILabel!
  @IBOutlet weak var yourWalletValueLabel: UILabel!
  @IBOutlet weak var yourAddressTextLabel: UILabel!
  @IBOutlet weak var yourAddressValueLabel: UILabel!
  
  @IBOutlet weak var advanceSettingsView: KAdvancedSettingsView!
  @IBOutlet weak var advanceSettingsViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  @IBOutlet var separatorViews: [UIView]!

  fileprivate var loadTimer: Timer?
  fileprivate(set) var viewModel: KWConfirmPaymentViewModel
  weak var delegate: KWConfirmPaymentViewControllerDelegate?

  public init(viewModel: KWConfirmPaymentViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KWConfirmPaymentViewController", bundle: Bundle.framework)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationItem.title = KWStringConfig.current.confirm
    self.viewModel.checkNeedToSendApproveToken {
      self.txDetailsTransactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
      self.transactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
    }
    self.loadTimer?.invalidate()
    self.reloadDataFromNode()
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadDataFromNode()
    })
  }

  func updateNeedToSendTokenApprove(_ needApprove: Bool) {
    self.viewModel.isNeedsToSendApprove = needApprove
    self.txDetailsTransactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
    self.transactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.separatorViews.forEach { view in
      view.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    }
    self.txDetailsSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.orderDetailsDataContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 4),
      opacity: 0.16,
      radius: 16
    )
    self.transactionDetailsContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 4),
      opacity: 0.16,
      radius: 16
    )
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupStepView()
    self.setupOrderDetailsView()
    self.setupTransactionDetailsView()
    self.setupCommonElements()
  }

  fileprivate func setupNavigationBar() {
    let image = UIImage(named: "back_white_icon", in: Bundle.framework, compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor
    self.navigationItem.title = KWStringConfig.current.confirm
  }

  fileprivate func setupStepView() {
    self.stepView.updateView(with: .confirm, dataType: self.viewModel.dataType)
  }

  fileprivate func setupOrderDetailsView() {
    self.orderDetailsTextLabel.text = KWStringConfig.current.orderDetails
    self.productNameLabel.text = self.viewModel.orderProductName
    self.orderAmountTextLabel.text = KWStringConfig.current.amount
    self.orderAmountLabel.text = self.viewModel.orderReceiveAmount
    self.transactionFeeTextLabel.text = KWStringConfig.current.transactionFee
    self.transactionFeeValueLabel.text = self.viewModel.orderTransactionFeeString
    self.receiverAddressLabel.attributedText = self.viewModel.orderDestAddressAttributedString
    self.orderDetailsDataContainerView.isHidden = self.viewModel.isOrderDetailsDataHidden
  }

  fileprivate func setupTransactionDetailsView() {
    self.transactionDetailsContainerView.isHidden = self.viewModel.isTransactionDetailsDataHidden
    self.fromTextLabel.text = KWStringConfig.current.from
    self.fromValueLabel.text = self.viewModel.transactionFromAmountString
    self.toTextLabel.text = KWStringConfig.current.to
    self.toValueLabel.text = self.viewModel.transactionToAmountString
    self.txDetailsTransactionFeeTextLabel.text = KWStringConfig.current.transactionFee
    self.txDetailsTransactionFeeValueLabel.text = self.viewModel.transactionFeeString
  }

  fileprivate func setupCommonElements() {
    if self.orderDetailsDataContainerView.isHidden {
      self.transactionTypeTopPaddingConstraint.constant = 275.0
    } else {
      self.productAvatarImageView.image = self.viewModel.orderProductAvatar
      self.productAvatarImageViewHeightConstraint.constant = self.viewModel.orderProductAvatar?.size.height ?? 0.0
      self.transactionTypeTopPaddingConstraint.constant = 340.0 + self.productAvatarImageViewHeightConstraint.constant
      self.viewModel.getProductAvatarIfNeeded { isSuccess in
        if isSuccess {
          self.productAvatarImageView.image = self.viewModel.orderProductAvatar
          self.productAvatarImageViewHeightConstraint.constant = self.viewModel.orderProductAvatar?.size.height ?? 0.0
          self.transactionTypeTopPaddingConstraint.constant = 340.0 + self.productAvatarImageViewHeightConstraint.constant
        }
      }
    }
    self.transactionTypeTextLabel.text = self.viewModel.transactionTypeText
    self.firstAmountLabel.text = self.viewModel.firstAmountText
    self.secondAmountLabel.attributedText = self.viewModel.secondAmountAttributedString
    self.yourWalletTextLabel.text = KWStringConfig.current.yourWallet
    self.yourWalletValueLabel.text = self.viewModel.yourWalletType
    self.yourAddressTextLabel.text = KWStringConfig.current.yourAddress
    self.yourAddressValueLabel.text = self.viewModel.yourWalletAddress
  
    let viewModel = KAdvancedSettingsViewModel(
      hasMinRate: self.viewModel.transaction.from != self.viewModel.transaction.to,
      sourceToken: self.viewModel.transaction.from.symbol,
      destToken: self.viewModel.transaction.to.symbol,
      dataType: self.viewModel.dataType
    )
    self.advanceSettingsView.delegate = self
    self.advanceSettingsView.updateViewModel(viewModel)
    self.advanceSettingsView.updateMinRate(
      percent: self.viewModel.minRatePercent,
      currentRate: Double(self.viewModel.expectedRate) / pow(10.0, Double(self.viewModel.transaction.to.decimals))
    )
    self.advanceSettingsViewHeightConstraint.constant = self.advanceSettingsView.height
    self.view.layoutIfNeeded()

    self.confirmButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonNormalBackgroundColor,
      forState: .normal
    )
    self.confirmButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonDisableBackgroundColor,
      forState: .disabled
    )
    self.confirmButton.setTitle(KWStringConfig.current.confirm, for: .normal)
    self.confirmButton.rounded(radius: 4.0)

    self.cancelButton.setTitle(KWStringConfig.current.cancel, for: .normal)

    self.separatorViews.forEach { view in
      view.dashLine(width: 1.0, color: UIColor.Kyber.border)
    }

    self.view.layoutIfNeeded()
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.delegate?.confirmPaymentViewController(self, run: .back)
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    if !self.viewModel.isBalanceEnoughAmountFrom {
      self.showAlertController(
        title: KWStringConfig.current.error,
        message: KWStringConfig.current.balanceIsNotEnoughToMakeTransaction
      )
      return
    }
    if !self.viewModel.isBalanceForPayTransaction {
      self.showAlertController(
        title: KWStringConfig.current.error,
        message: KWStringConfig.current.balanceIsNotEnoughMinRatePayTransaction
      )
      return
    }
    if !self.viewModel.isMinRateValid {
      self.showAlertController(
        title: KWStringConfig.current.error,
        message: KWStringConfig.current.minRateInvalid
      )
      return
    }
    self.delegate?.confirmPaymentViewController(self, run: .confirm(transaction: self.viewModel.newTransaction))
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.confirmPaymentViewController(self, run: .back)
  }

  fileprivate func reloadDataFromNode() {
    self.viewModel.getEstimatedGasLimit {
      self.txDetailsTransactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
      self.transactionFeeValueLabel.text = self.viewModel.displayTransactionFeeETH
    }
    self.viewModel.getBalance { }
    self.viewModel.getExpectedRateRequest {
      self.firstAmountLabel.text = self.viewModel.firstAmountText
      self.secondAmountLabel.attributedText = self.viewModel.secondAmountAttributedString
      self.orderAmountLabel.text = self.viewModel.orderReceiveAmount
      self.fromValueLabel.text = self.viewModel.transactionFromAmountString
      self.toValueLabel.text = self.viewModel.transactionToAmountString
      self.advanceSettingsView.updateMinRate(
        percent: self.viewModel.minRatePercent,
        currentRate: Double(self.viewModel.expectedRate) / pow(10.0, Double(self.viewModel.transaction.to.decimals))
      )
    }
    KWGasCoordinator.shared.getKNCachedGasPrice {
      self.viewModel.updateGasPriceType(self.viewModel.gasPriceType)
      self.advanceSettingsView.updateGasPrices(
        fast: KWGasCoordinator.shared.fastGas,
        medium: KWGasCoordinator.shared.mediumGas,
        slow: KWGasCoordinator.shared.slowGas
      )
      self.updateTransactionGas()
    }
  }

  fileprivate func updateTransactionGas() {
    self.txDetailsTransactionFeeValueLabel.text = self.viewModel.transactionFeeString
    self.transactionFeeValueLabel.text = self.viewModel.orderTransactionFeeString
    self.view.layoutIfNeeded()
  }
}

extension KWConfirmPaymentViewController: KAdvancedSettingsViewDelegate {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent) {
    switch event {
    case .gasPriceChanged(let type):
      self.viewModel.updateGasPriceType(type)
      self.updateTransactionGas()
    case .minRatePercentageChanged(let percent):
      self.viewModel.updateMinRatePercent(percent)
    case .infoPressed: break
    case .displayButtonPressed:
      self.advanceSettingsViewHeightConstraint.constant = self.advanceSettingsView.height
      self.view.layoutIfNeeded()
    }
  }
}
