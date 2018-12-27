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

  @IBOutlet weak var payDetailsContainerView: UIView!
  @IBOutlet weak var orderDetailsLabel: UILabel!
  @IBOutlet weak var payDestAddressLabel: UILabel!
  @IBOutlet weak var payAmountTextLabel: UILabel!
  @IBOutlet weak var payDestAmountLabel: UILabel!
  @IBOutlet weak var payProductNameLabel: UILabel!
  @IBOutlet weak var payProductQtyLabel: UILabel!
  @IBOutlet weak var payProductAvatarImageView: UIImageView!
  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var orderDetailsTextHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var heightConstraintForProductAvatar: NSLayoutConstraint!
  @IBOutlet weak var topPaddingProductNameConstraint: NSLayoutConstraint!
  @IBOutlet weak var topPaddingProductAvatarConstraint: NSLayoutConstraint!
  @IBOutlet weak var topPaddingAmountTextConstraint: NSLayoutConstraint!
  @IBOutlet weak var topPaddingAddressTextConstraint: NSLayoutConstraint!

  @IBOutlet weak var bottomPaddingDestAddressLabel: NSLayoutConstraint!
  @IBOutlet weak var topPaddingConstraintForTopTextLabel: NSLayoutConstraint!
  @IBOutlet weak var topStringTextLabel: UILabel!

  @IBOutlet weak var heightConstraintForTokenContainerView: NSLayoutConstraint!
  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var fromDropImageView: UIImageView!
  @IBOutlet weak var tokenAmountTextField: UITextField!
  @IBOutlet weak var receiveTokenButton: UIButton!
  @IBOutlet weak var toDropImageView: UIImageView!
  @IBOutlet weak var receiveAmountLabel: UILabel!
  @IBOutlet weak var heightConstraintForReceiveTokenData: NSLayoutConstraint!
  @IBOutlet weak var toButton: UIButton!
  @IBOutlet weak var tokensSeparatorView: UIView!

  @IBOutlet weak var estimateRateLoadingView: UIActivityIndicatorView!
  @IBOutlet weak var estimateRateLabel: UILabel!
  @IBOutlet weak var nextButton: UIButton!

  @IBOutlet weak var agreeTermsAndConditionsLabel: UILabel!
  @IBOutlet weak var agreeTermsAndConditionsButton: UIButton!
  @IBOutlet weak var agreeTextLabel: UILabel!

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

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.payDetailsContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 4),
      opacity: 0.16,
      radius: 16
    )
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupStepView()
    self.setupDestAddressView()
    self.setupFromTokenView()
    self.setupEstimatedRate()
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
    self.payDetailsContainerView.isHidden = self.viewModel.isPayOrderDetailsContainerHidden
    self.payProductNameLabel.text = self.viewModel.productName
    self.payProductQtyLabel.text = {
      if let qty = self.viewModel.productQty, qty > 0 {
        return "X \(qty)"
      }
      return nil
    }()
    self.payDestAmountLabel.text = self.viewModel.payDestAmountText
    self.payProductAvatarImageView.isHidden = self.viewModel.isProductAvatarImageViewHidden
    self.payProductAvatarImageView.image = self.viewModel.productAvatarImage
    self.payProductAvatarImageView.rounded(radius: 5.0)

    self.orderDetailsTextHeightConstraint.constant = self.viewModel.payOrderDetailsTextContainerViewHeight
    self.topPaddingProductNameConstraint.constant = self.viewModel.topPaddingProductName
    self.topPaddingProductAvatarConstraint.constant = self.viewModel.topPaddingProductAvatar
    self.topPaddingAmountTextConstraint.constant = self.viewModel.topPaddingForDestAmountLabel
    self.topPaddingAddressTextConstraint.constant = self.viewModel.topPaddingPayDestAddressLabel
    self.bottomPaddingDestAddressLabel.constant = self.viewModel.bottomPaddingPayDestAddressLabel
    self.heightConstraintForProductAvatar.constant = self.viewModel.heightProductAvatarImage

    self.payDestAddressLabel.attributedText = self.viewModel.payDestAddressAttributedString
    self.payDestAmountLabel.text = self.viewModel.payDestAmountText

    self.view.updateConstraints()

    self.viewModel.getProductAvatarIfNeeded { [weak self] needsUpdate in
      guard let `self` = self else { return }
      if !needsUpdate { return }
      self.payProductAvatarImageView.isHidden = self.viewModel.isProductAvatarImageViewHidden
      self.payProductAvatarImageView.image = self.viewModel.productAvatarImage

      self.topPaddingProductAvatarConstraint.constant = self.viewModel.topPaddingProductAvatar
      self.heightConstraintForProductAvatar.constant = self.viewModel.heightProductAvatarImage
      self.view.updateConstraints()
    }
  }

  fileprivate func setupFromTokenView() {
    self.tokenContainerView.rounded(radius: 4.0)
    self.topPaddingConstraintForTopTextLabel.constant = self.viewModel.isPayOrderDetailsContainerHidden ? 0.0 : 24.0
    self.topStringTextLabel.text = self.viewModel.topStringText
    self.topStringTextLabel.textColor = self.viewModel.topStringTextColor

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
    self.receiveTokenButton.isEnabled = self.viewModel.isToButtonEnabled
    self.toDropImageView.isHidden = !self.viewModel.isToButtonEnabled || self.viewModel.isToButtonHidden
    self.receiveAmountLabel.isHidden = self.viewModel.isToButtonHidden
    self.receiveAmountLabel.textColor = KWThemeConfig.current.amountTextFieldDisable

    self.heightConstraintForTokenContainerView.constant = self.viewModel.heightForTokenData
    self.heightConstraintForReceiveTokenData.constant = self.viewModel.heightForReceiverTokenView

    self.updateSelectedToken()
  }

  fileprivate func setupEstimatedRate() {
    self.updateEstimatedRate()
  }

  fileprivate func setupTermsAndConditions() {
    self.agreeTermsAndConditionsButton.rounded(
      color: self.viewModel.hasAgreed ? .clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.agreeTextLabel.text = KWStringConfig.current.agreeTo
    let agreeGesture = UITapGestureRecognizer(target: self, action: #selector(self.agreeTermsAndConditionsCheckBoxPressed(_:)))
    self.agreeTextLabel.addGestureRecognizer(agreeGesture)
    self.agreeTextLabel.isUserInteractionEnabled = true

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
    self.payDestAmountLabel.text = self.viewModel.payDestAmountText
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
    self.payDestAmountLabel.text = self.viewModel.payDestAmountText
    self.updateViewConstraints()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
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
    if self.viewModel.isAmountTooSmall {
      self.showAlertController(
        title: "Amount too small",
        message: "Amount should be greater than 0.001 ETH"
      )
      return
    }
    self.delegate?.paymentMethodViewController(self, run: .next(transaction: self.viewModel.transaction))
  }

  fileprivate func reloadDataFromNode(isFirstTime: Bool = false) {
    self.viewModel.getExpectedRateRequest {
      self.coordinatorUpdateExpectedRate()
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
      self.receiveAmountLabel.text = self.viewModel.estimatedReceiverAmountString
      self.payDestAmountLabel.text = self.viewModel.payDestAmountText
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
    self.updateViewAmountDidChange()
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateDefaultPair(from: String, to: String) {
    guard let from = self.viewModel.tokens.first(where: { $0.symbol == from}),
      let to = self.viewModel.tokens.first(where: { $0.symbol == to }) else {
        return
    }
    self.viewModel.updateDefaultPairTokens(from: from, to: to)
    self.updateSelectedToken()
    self.reloadDataFromNode()
    self.updateEstimatedRate()
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

  func coordinatorUpdateSupportedTokens(_ tokens: [KWTokenObject]) {
    self.viewModel.updateSupportedTokens(tokens)
  }
}
