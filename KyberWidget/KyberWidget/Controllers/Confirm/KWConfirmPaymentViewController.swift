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
  case confirmPayment(payment: KWPayment)
}

public protocol KWConfirmPaymentViewControllerDelegate: class {
  func confirmPaymentViewController(_ controller: KWConfirmPaymentViewController, run event: KWConfirmPaymentViewEvent)
}

public class KWConfirmPaymentViewController: UIViewController {

  @IBOutlet weak var stepView: KWStepView!

  @IBOutlet weak var paymentDataView: UIView!
  @IBOutlet weak var destAddressLabel: UILabel!
  @IBOutlet weak var amounToPayTextLabel: UILabel!
  @IBOutlet weak var estimateSrcAmountLabel: UILabel!
  @IBOutlet weak var estimateDestAmountLabel: UILabel!

  @IBOutlet weak var swapDataView: UIView!
  @IBOutlet weak var fromAmountLabel: UILabel!
  @IBOutlet weak var toAmountLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var expectedRateLabel: UILabel!

  @IBOutlet weak var minAcceptableRateTextLabel: UILabel!
  @IBOutlet weak var minRateLabel: UILabel!

  @IBOutlet weak var gasPriceTopPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var gasPriceLabel: UILabel!
  @IBOutlet weak var transactionFeeLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  @IBOutlet var separatorViews: [UIView]!

  fileprivate var loadTimer: Timer?
  fileprivate var viewModel: KWConfirmPaymentViewModel
  weak var delegate: KWConfirmPaymentViewControllerDelegate?

  public init(viewModel: KWConfirmPaymentViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KWConfirmPaymentViewController", bundle: Bundle(identifier: "manhlx.kyber.network.KyberWidget"))
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
    self.loadTimer?.invalidate()
    self.reloadDataFromNode()
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadDataFromNode()
    })
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.separatorViews.forEach { view in
      view.dashLine(width: 1.0, color: UIColor.Kyber.border)
    }
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupStepView()
    self.setupPaymentDataView()
    self.setupSwapDataView()
    self.setupCommonElements()
  }

  fileprivate func setupPaymentDataView() {
    self.paymentDataView.isHidden = self.viewModel.isPaymentDataViewHidden
    self.destAddressLabel.attributedText = self.viewModel.paymentDestAddressAttributedString

    self.amounToPayTextLabel.text = KWStringConfig.current.amountToPay
    self.amounToPayTextLabel.textColor = KWThemeConfig.current.confirmAmountToPayTextColor

    self.estimateSrcAmountLabel.text = self.viewModel.paymentFromAmountString
    self.estimateSrcAmountLabel.textColor = KWThemeConfig.current.confirmPayFromAmountColor

    self.estimateDestAmountLabel.text = self.viewModel.paymentEstimatedReceivedAmountString
    self.estimateDestAmountLabel.textColor = KWThemeConfig.current.confirmPayReceivedAmountColor
  }

  fileprivate func setupSwapDataView() {
    self.swapDataView.isHidden = self.viewModel.isSwapDataViewHidden
    self.fromAmountLabel.text = self.viewModel.swapFromAmountString
    self.fromAmountLabel.textColor = KWThemeConfig.current.confirmSwapFromAmountColor

    self.toAmountLabel.text = self.viewModel.swapToAmountString
    self.toAmountLabel.textColor = KWThemeConfig.current.confirmSwapToAmountColor

    self.toTextLabel.text = "\(KWStringConfig.current.to):"
    self.toTextLabel.textColor = KWThemeConfig.current.confirmToTextColor

    self.expectedRateLabel.text = self.viewModel.swapExpectedRateString
    self.expectedRateLabel.textColor = KWThemeConfig.current.confirmSwapExpectedRateColor
  }

  fileprivate func setupNavigationBar() {
    let image = UIImage(named: "back_white_icon", in: Bundle(identifier: "manhlx.kyber.network.KyberWidget"), compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor
    self.navigationItem.title = KWStringConfig.current.confirm
  }

  fileprivate func setupStepView() {
    self.stepView.updateView(with: .confirm, isPayment: self.viewModel.dataType == .payment)
  }

  fileprivate func setupCommonElements() {
    self.minAcceptableRateTextLabel.text = KWStringConfig.current.minAcceptableRate
    self.minAcceptableRateTextLabel.isHidden = self.viewModel.isMinRateHidden
    self.minRateLabel.isHidden = self.viewModel.isMinRateHidden
    self.minRateLabel.text = self.viewModel.displayMinRate

    self.gasPriceTopPaddingConstraint.constant = self.viewModel.isMinRateHidden ? 32.0 : 64.0
    self.gasPriceTextLabel.text = KWStringConfig.current.gasFee + " (Gwei)"
    self.gasPriceLabel.text = self.viewModel.displayGasPrice
    self.transactionFeeLabel.text = self.viewModel.displayTransactionFeeETH

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
    self.delegate?.confirmPaymentViewController(self, run: .confirmPayment(payment: self.viewModel.newPayment))
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.confirmPaymentViewController(self, run: .back)
  }

  fileprivate func reloadDataFromNode() {
    self.viewModel.getEstimatedGasLimit {
      self.transactionFeeLabel.text = self.viewModel.displayTransactionFeeETH
    }
  }
}
