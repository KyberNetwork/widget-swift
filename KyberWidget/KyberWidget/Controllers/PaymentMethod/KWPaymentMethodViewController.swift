//
//  KWPaymentMethodViewController.swift
//  KyberPayiOS
//
//  Created by Manh Le on 22/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt
import SafariServices

public enum KWPaymentMethodViewEvent {
  case close
  case searchToken(token: KWTokenObject, isSource: Bool)
  case next(transaction: KWTransaction)
}

public protocol KWPaymentMethodViewControllerDelegate: class {
  func paymentMethodViewController(_ controller: KWPaymentMethodViewController, run event: KWPaymentMethodViewEvent)
}

public class KWPaymentMethodViewController: UIViewController {

  @IBOutlet weak var stepView: KWStepView!

  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var youAreAboutToPayTextLabel: UILabel!
  @IBOutlet weak var destAddressLabel: UILabel!
  @IBOutlet weak var destAmountLabel: UILabel!
  @IBOutlet weak var destDataContainerView: UIView!
  @IBOutlet weak var heightConstraintForDestDataView: NSLayoutConstraint!
  @IBOutlet weak var topPaddingConstraintForDestAmountLabel: NSLayoutConstraint!

  @IBOutlet weak var advancedSettingsView: KAdvancedSettingsView!
  @IBOutlet weak var advancedSettingsHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var advancedSettingsTopPaddingConstraint: NSLayoutConstraint!

  @IBOutlet weak var payWithTextLabel: UILabel!
  
  @IBOutlet weak var heightConstraintForTokenContainerView: NSLayoutConstraint!
  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var tokenAmountTextField: UITextField!
  @IBOutlet weak var receiveTokenButton: UIButton!
  @IBOutlet weak var receiveAmountLabel: UILabel!
  @IBOutlet weak var heightConstraintForReceiveTokenData: NSLayoutConstraint!
  @IBOutlet weak var toButton: UIButton!
  @IBOutlet weak var tokensSeparatorView: UIView!

  @IBOutlet weak var estimateRateLoadingView: UIActivityIndicatorView!
  @IBOutlet weak var estimateRateLabel: UILabel!
  @IBOutlet weak var estimateDestAmountLabel: UILabel!
  @IBOutlet weak var nextButton: UIButton!

  @IBOutlet weak var agreeTermsAndConditionsLabel: UILabel!
  @IBOutlet weak var agreeTermsAndConditionsButton: UIButton!

  fileprivate var viewModel: KWPaymentMethodViewModel
  weak var delegate: KWPaymentMethodViewControllerDelegate?
  fileprivate var loadTimer: Timer?

  public init(viewModel: KWPaymentMethodViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KWPaymentMethodViewController", bundle: Bundle.framework)
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
    self.navigationItem.title = self.viewModel.navigationTitle
    self.loadTimer?.invalidate()
    self.reloadDataFromNode(isFirstTime: true)
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadDataFromNode()
    })
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.advancedSettingsView.layoutSubviews()
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupStepView()
    self.setupDestAddressView()
    self.setupFromTokenView()
    self.setupEstimatedRate()
    self.setupAdvancedSettingsView()
    self.setupTermsAndConditions()
    self.setupNextButton()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = self.viewModel.navigationTitle
    let image = UIImage(named: "back_white_icon", in: Bundle.framework, compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor
  }

  fileprivate func setupStepView() {
    self.stepView.updateView(
      with: .chooseToken,
      dataType: self.viewModel.dataType
    )
  }

  fileprivate func setupDestAddressView() {
    self.destDataContainerView.isHidden = self.viewModel.isDestDataViewHidden
    self.destAddressLabel.isHidden = self.viewModel.isDestAddressLabelHidden
    self.destAmountLabel.isHidden = self.viewModel.isDestAmountLabelHidden
    self.heightConstraintForDestDataView.constant = self.viewModel.heightForDestDataView
    self.topPaddingConstraintForDestAmountLabel.constant = self.viewModel.topPaddingForDestAmountLabel

    self.youAreAboutToPayTextLabel.text = self.viewModel.destDataTitleLabelString
    self.destAddressLabel.attributedText = self.viewModel.destAddressAttributedString
    self.destAmountLabel.attributedText = self.viewModel.destAmountAttributedString
  }

  fileprivate func setupFromTokenView() {
    self.tokenContainerView.rounded(radius: 4.0)
    self.payWithTextLabel.text = self.viewModel.transactionTypeText

    self.tokenAmountTextField.isEnabled = self.viewModel.isFromAmountTextFieldEnabled
    self.tokenAmountTextField.textColor = self.viewModel.fromAmountTextFieldColor
    self.tokenAmountTextField.adjustsFontSizeToFitWidth = true

    self.tokenAmountTextField.delegate = self
    self.viewModel.updateFromAmount("")
    self.tokenAmountTextField.text = ""

    self.toButton.rounded(radius: self.toButton.frame.height / 2.0)
    self.toButton.isHidden = self.viewModel.isToButtonHidden
    self.tokensSeparatorView.isHidden = self.viewModel.isToButtonHidden
    self.receiveTokenButton.isHidden = self.viewModel.isToButtonHidden
    self.receiveAmountLabel.isHidden = self.viewModel.isToButtonHidden
    self.receiveAmountLabel.textColor = KWThemeConfig.current.amountTextFieldDisable

    self.heightConstraintForTokenContainerView.constant = self.viewModel.heightForTokenData
    self.heightConstraintForReceiveTokenData.constant = self.viewModel.heightForReceiverTokenView

    self.updateSelectedToken()
  }

  fileprivate func setupEstimatedRate() {
    self.estimateDestAmountLabel.isHidden = self.viewModel.isEstimateDestAmountHidden
    self.updateEstimatedRate()
  }

  fileprivate func setupAdvancedSettingsView() {
    let viewModel = KAdvancedSettingsViewModel(hasMinRate: true)
    viewModel.updateGasPrices(
      fast: KWGasCoordinator.shared.fastGas,
      medium: KWGasCoordinator.shared.mediumGas,
      slow: KWGasCoordinator.shared.slowGas
    )
    viewModel.updateGasLimit(self.viewModel.gasLimit)
    let minRateString: String = self.viewModel.minRateText ?? "0"
    let percent: CGFloat = CGFloat(self.viewModel.currentMinRatePercentValue)
    viewModel.updateMinRateValue(minRateString, percent: percent)
    viewModel.updateViewHidden(isHidden: true)
    self.advancedSettingsView.updateViewModel(viewModel)
    self.advancedSettingsHeightConstraint.constant = self.advancedSettingsView.height
    self.advancedSettingsView.delegate = self
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraints()
  }

  fileprivate func setupTermsAndConditions() {
    self.agreeTermsAndConditionsButton.rounded(
      color: self.viewModel.hasAgreed ? .clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.agreeTermsAndConditionsButton.backgroundColor = .white
    self.agreeTermsAndConditionsLabel.attributedText = self.viewModel.termsAndConditionsAttributedString
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openTermsAndConditionsView(_:)))
    self.agreeTermsAndConditionsLabel.isUserInteractionEnabled = true
    self.agreeTermsAndConditionsLabel.addGestureRecognizer(tapGesture)
  }

  fileprivate func setupNextButton() {
    self.nextButton.rounded(radius: 5.0)
    self.nextButton.setTitle(KWStringConfig.current.next, for: .normal)
    self.nextButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonNormalBackgroundColor,
      forState: .normal
    )
    self.nextButton.setTitleColor(
      .white,
      for: .normal
    )
    self.nextButton.setBackgroundColor(
      KWThemeConfig.current.actionButtonDisableBackgroundColor,
      forState: .disabled
    )
    self.nextButton.setTitleColor(
      .white,
      for: .disabled
    )
    self.updateNextButton()
  }

  fileprivate func updateSelectedToken() {
    self.tokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.tokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: true),
      for: .normal
    )
    if self.tokenAmountTextField.isEnabled {
      self.tokenAmountTextField.text = self.viewModel.amountFrom
    } else {
      self.tokenAmountTextField.text = self.viewModel.estimatedFromAmountDisplay
      self.viewModel.updateFromAmount(self.tokenAmountTextField.text ?? "")
    }

    self.receiveTokenButton.setTokenImage(
      token: self.viewModel.to,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.receiveTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: false),
      for: .normal
    )
    self.receiveAmountLabel.text = self.viewModel.estimatedReceiverAmountString
    self.updateAdvancedSettingsView()
  }

  fileprivate func updateEstimatedRate() {
    self.estimateRateLoadingView.isHidden = self.viewModel.isLoadingEstimatedRateHidden
    if self.estimateRateLoadingView.isHidden {
      self.estimateRateLoadingView.stopAnimating()
    } else {
      self.estimateRateLoadingView.startAnimating()
    }
    self.estimateRateLabel.isHidden = self.viewModel.isEstimatedRateHidden
    self.estimateRateLabel.text = self.viewModel.estimatedExchangeRateText
    self.estimateDestAmountLabel.attributedText = self.viewModel.estimateDestAmountAttributedString
    let topPadding: CGFloat = {
      if self.viewModel.isEstimatedRateHidden && self.viewModel.isEstimateDestAmountHidden {
        return 32.0
      }
      if !self.viewModel.isEstimateDestAmountHidden && !self.viewModel.isEstimatedRateHidden {
        return 81.0
      }
      return 56.0
    }()
    self.advancedSettingsTopPaddingConstraint.constant = topPadding
    self.updateViewConstraints()
  }

  fileprivate func updateAdvancedSettingsView() {
    let minRateString: String = self.viewModel.minRateText ?? "0"
    let percent: CGFloat = CGFloat(self.viewModel.currentMinRatePercentValue)
    self.advancedSettingsView.updateMinRate(minRateString, percent: percent)

    self.advancedSettingsView.updateGasPrices(
      fast: KWGasCoordinator.shared.fastGas,
      medium: KWGasCoordinator.shared.mediumGas,
      slow: KWGasCoordinator.shared.slowGas,
      gasLimit: self.viewModel.gasLimit
    )
    if self.advancedSettingsView.updateHasMinRate(self.viewModel.from != self.viewModel.to) {
      self.advancedSettingsHeightConstraint.constant = self.advancedSettingsView.height
      self.view.updateConstraints()
    }
    self.updateViewConstraints()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      if self.viewModel.isAmountTooSmall { return false }
      if !self.viewModel.isMinRateValidForTransaction { return false }
      if self.viewModel.estimatedRate == nil { return false }
      if !self.viewModel.hasAgreed { return false }
      return true
    }()
    self.nextButton.isEnabled = enabled
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.delegate?.paymentMethodViewController(self, run: .close)
  }

  @IBAction func agreeTermsAndConditionsCheckBoxPressed(_ sender: Any) {
    self.viewModel.hasAgreed = !self.viewModel.hasAgreed
    self.agreeTermsAndConditionsButton.rounded(
      color: self.viewModel.hasAgreed ? .clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    let image = UIImage(named: "done_white_icon", in: Bundle.framework, compatibleWith: nil)
    self.agreeTermsAndConditionsButton.backgroundColor = self.viewModel.hasAgreed ? UIColor.Kyber.shamrock : UIColor.white
    self.agreeTermsAndConditionsButton.setImage(
      self.viewModel.hasAgreed ? image : nil, for: .normal)
    self.updateNextButton()
  }

  @objc func openTermsAndConditionsView(_ sender: Any) {
    let url = URL(string: "https://files.kyber.network/tac.html")!
    let safariVC = SFSafariViewController(url: url)
    self.present(safariVC, animated: true, completion: nil)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.delegate?.paymentMethodViewController(
      self,
      run: .searchToken(token: self.viewModel.from, isSource: true)
    )
  }

  @IBAction func receiveTokenButtonPressed(_ sender: Any) {
    self.delegate?.paymentMethodViewController(
      self,
      run: .searchToken(token: self.viewModel.from, isSource: false)
    )
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    self.delegate?.paymentMethodViewController(self, run: .next(transaction: self.viewModel.transaction))
  }

  fileprivate func reloadDataFromNode(isFirstTime: Bool = false) {
    self.viewModel.getExpectedRateRequest {
      self.coordinatorUpdateExpectedRate()
    }
    KWGasCoordinator.shared.getKNCachedGasPrice {
      self.viewModel.updateEstimatedGasPrices()
      self.updateAdvancedSettingsView()
    }
    self.viewModel.getEstimatedGasLimit {
      self.coordinatorUpdateEstGasLimit()
    }
  }
}

extension KWPaymentMethodViewController: UITextFieldDelegate {
  public func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFromAmount("")
    self.updateViewAmountDidChange()
    return false
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if text.toBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    textField.text = text
    self.viewModel.updateFromAmount(text)
    self.updateViewAmountDidChange()
    return false
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.isFromAmountTextFieldEnabled {
      // update estimate dest amount
      self.tokenAmountTextField.text = self.viewModel.amountFrom
      self.estimateDestAmountLabel.attributedText = self.viewModel.estimateDestAmountAttributedString
      self.receiveAmountLabel.text = self.viewModel.estimatedReceiverAmountString
    } else {
      // update expected source amount
      self.tokenAmountTextField.text = self.viewModel.estimatedFromAmountDisplay
      self.viewModel.updateFromAmount(self.tokenAmountTextField.text ?? "")
    }
    self.updateNextButton()
  }
}

// MARK: Update from coordinator
extension KWPaymentMethodViewController {
  func coordinatorUpdateExpectedRate() {
    self.updateEstimatedRate()
    self.updateAdvancedSettingsView()
    self.updateViewAmountDidChange()
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdatePayToken(_ token: KWTokenObject, isSource: Bool) {
    if self.viewModel.updateSelectedToken(token, isSource: isSource) {
      self.updateSelectedToken()
      self.reloadDataFromNode()
      self.updateEstimatedRate()
      self.updateViewAmountDidChange()
      self.view.layoutIfNeeded()
    }
  }
  
  func coordinatorUpdateEstGasLimit() {
    self.updateAdvancedSettingsView()
  }

  func coordinatorUpdateSupportedTokens(_ tokens: [KWTokenObject]) {
    self.viewModel.updateSupportedTokens(tokens)
  }
}

// MARK: Advanced Settings View
extension KWPaymentMethodViewController: KAdvancedSettingsViewDelegate {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent) {
    switch event {
    case .displayButtonPressed:
      UIView.animate(
        withDuration: 0.32,
        animations: {
          self.advancedSettingsHeightConstraint.constant = self.advancedSettingsView.height
          self.updateAdvancedSettingsView()
          self.view.layoutIfNeeded()
      }, completion: { _ in
        if self.advancedSettingsView.isExpanded {
          let bottomOffset = CGPoint(
            x: 0,
            y: self.scrollContainerView.contentSize.height - self.scrollContainerView.bounds.size.height
          )
          self.scrollContainerView.setContentOffset(bottomOffset, animated: true)
        }
      })
    case .gasPriceChanged(let type):
      self.viewModel.updateSelectedGasPriceType(type)
      self.updateAdvancedSettingsView()
    case .minRatePercentageChanged(let percent):
      self.viewModel.updateExchangeMinRatePercent(Double(percent))
      self.updateAdvancedSettingsView()
    case .infoPressed:
      let minRateDescVC: KWMinAcceptableRatePopupViewController = {
        let viewModel = KWMinAcceptableRatePopupViewModel(
          minRate: self.viewModel.minRateText ?? "0.0",
          symbol: self.viewModel.to.symbol
        )
        return KWMinAcceptableRatePopupViewController(viewModel: viewModel)
      }()
      minRateDescVC.modalPresentationStyle = .overFullScreen
      minRateDescVC.modalTransitionStyle = .crossDissolve
      self.present(minRateDescVC, animated: true, completion: nil)
    }
  }
}
