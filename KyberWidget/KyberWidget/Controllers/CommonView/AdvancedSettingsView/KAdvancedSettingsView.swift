// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KAdvancedSettingsViewEvent {
  case infoPressed
  case displayButtonPressed
  case gasPriceChanged(type: KWGasPriceType)
  case minRatePercentageChanged(percent: Double)
}

protocol KAdvancedSettingsViewDelegate: class {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent)
}

class KAdvancedSettingsViewModel: NSObject {

  private let kGasPriceContainerHeight: CGFloat = 110
  private let kMinRateContainerHeight: CGFloat = 144

  fileprivate(set) var fast: BigInt = KWGasCoordinator.shared.fastGas
  fileprivate(set) var medium: BigInt = KWGasCoordinator.shared.mediumGas
  fileprivate(set) var slow: BigInt = KWGasCoordinator.shared.slowGas

  fileprivate(set) var selectedType: KWGasPriceType = .medium

  fileprivate(set) var isViewHidden: Bool = true
  fileprivate(set) var hasMinRate: Bool = true
  fileprivate(set) var dataType: KWDataType

  let sourceToken: String
  let destToken: String

  var minRateString: String {
    return "\((100.0 - minRatePercent) * currentRate / 100.0)"
  }
  fileprivate(set) var minRatePercent: Double = 3.0
  fileprivate(set) var currentRate: Double

  fileprivate(set) var minRateType: Int = 0 // 0: 3%, 1: any, 2: custom

  init(hasMinRate: Bool, sourceToken: String, destToken: String, dataType: KWDataType) {
    self.hasMinRate = hasMinRate
    self.sourceToken = sourceToken
    self.destToken = destToken
    self.currentRate = 0
    self.minRateType = 0
    self.dataType = dataType
  }

  var isGasPriceViewHidden: Bool { return self.isViewHidden }
  var gasPriceViewHeight: CGFloat { return self.isGasPriceViewHidden ? 0 : kGasPriceContainerHeight }

  lazy var numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 1
    formatter.minimumIntegerDigits = 1
    return formatter
  }()

  var fastGasString: String {
    let double = Double(self.fast) / Double(KWEthereumUnit.gwei.rawValue)
    return self.numberFormatter.string(from: NSNumber(value: double)) ?? "\(double)"
  }
  var mediumGasString: String {
    let double = Double(self.medium) / Double(KWEthereumUnit.gwei.rawValue)
    return self.numberFormatter.string(from: NSNumber(value: double)) ?? "\(double)"
  }
  var slowGasString: String {
    let double = Double(self.slow) / Double(KWEthereumUnit.gwei.rawValue)
    return self.numberFormatter.string(from: NSNumber(value: double)) ?? "\(double)"
  }

  var isMinRateViewHidden: Bool { return !self.hasMinRate || self.isViewHidden }
  var minRateViewHeight: CGFloat { return self.isMinRateViewHidden ? 0 : kMinRateContainerHeight }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt) {
    self.fast = fast
    self.medium = medium
    self.slow = slow
  }

  func updateSelectedType(_ type: KWGasPriceType) {
    self.selectedType = type
  }

  func updateViewHidden(isHidden: Bool) { self.isViewHidden = isHidden }

  func updateMinRateValue(type: Int, percent: Double, currentRate: Double) {
    self.minRateType = type
    self.currentRate = currentRate
    self.minRatePercent = percent
  }

  func updateHasMinRate(hasMinRate: Bool) { self.hasMinRate = hasMinRate }

  var totalHeight: CGFloat {
    var height: CGFloat = 20.0 + 24.0 + 10.0 // top padding, button control height, bottom padding
    height += self.gasPriceViewHeight
    height += self.minRateViewHeight
    return height
  }
}

class KAdvancedSettingsView: KWXibLoaderView {

  @IBOutlet weak var displayViewButton: UIButton!

  @IBOutlet weak var heightConstraintGasPriceContainerView: NSLayoutConstraint!
  @IBOutlet weak var gasPriceContainerView: UIView!
  @IBOutlet weak var fasGasValueLabel: UILabel!
  @IBOutlet weak var fasGasButton: UIButton!

  @IBOutlet weak var mediumGasValueLabel: UILabel!
  @IBOutlet weak var mediumGasButton: UIButton!

  @IBOutlet weak var slowGasValueLabel: UILabel!
  @IBOutlet weak var slowGasButton: UIButton!
  @IBOutlet weak var gasPriceSeparatorView: UIView!

  @IBOutlet weak var minRateContainerView: UIView!
  @IBOutlet weak var stillProceedIfRateGoesDownByLabel: UILabel!
  @IBOutlet weak var transactionRevertedDescLabel: UILabel!
  @IBOutlet weak var heightConstraintMinRateContainerView: NSLayoutConstraint!
  @IBOutlet weak var minRateThreePercentButton: UIButton!
  @IBOutlet weak var minRateAnyRateButton: UIButton!
  @IBOutlet weak var minRateCustomButton: UIButton!
  @IBOutlet weak var minRateCustomTextField: UITextField!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate var viewModel: KAdvancedSettingsViewModel!
  weak var delegate: KAdvancedSettingsViewDelegate?

  var height: CGFloat {
    if self.viewModel == nil { return 20.0 + 24.0 + 10.0 }
    return self.viewModel.totalHeight
  }

  var isExpanded: Bool { return !self.viewModel.isViewHidden }

  override func commonInit() {
    super.commonInit()
    self.gasPriceSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.minRateCustomTextField.delegate = self

    self.cancelButton.setImage(
      UIImage(named: "cancel_icon", in: Bundle.framework, compatibleWith: nil),
      for: .normal
    )
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.gasPriceSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  func updateViewModel(_ viewModel: KAdvancedSettingsViewModel) {
    self.viewModel = viewModel
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
  }

  fileprivate func updateGasPriceUIs() {
    if self.viewModel == nil { return }
    self.gasPriceContainerView.isHidden = self.viewModel.isGasPriceViewHidden
    self.heightConstraintGasPriceContainerView.constant = self.viewModel.gasPriceViewHeight

    self.fasGasValueLabel.text = self.viewModel.fastGasString
    self.mediumGasValueLabel.text = self.viewModel.mediumGasString
    self.slowGasValueLabel.text = self.viewModel.slowGasString

    let selectedColor = UIColor.Kyber.shamrock
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 8.0
    let normalWidth: CGFloat = 1.0

    self.fasGasButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.mediumGasButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.mediumGasButton.frame.height / 2.0
    )

    self.slowGasButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasButton.frame.height / 2.0
    )
    self.layoutIfNeeded()
  }

  fileprivate func updateMinRateUIs() {
    if self.viewModel == nil { return }
    self.stillProceedIfRateGoesDownByLabel.text = String(format: KWStringConfig.current.stillProceedIfRateGoesDownBy, "\(self.viewModel.sourceToken)-\(self.viewModel.destToken)")
    self.transactionRevertedDescLabel.text = String(
      format: KWStringConfig.current.transactionWillRevertIfRateLower,
      arguments: ["\(self.viewModel.sourceToken)-\(self.viewModel.destToken)",
        "\(self.viewModel.minRateString.prefix(12))", "\("\(self.viewModel.currentRate)".prefix(12))"])

    self.minRateContainerView.isHidden = self.viewModel.isMinRateViewHidden
    if self.minRateContainerView.isHidden { return }

    let selectedColor = UIColor.Kyber.shamrock
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 8.0
    let normalWidth: CGFloat = 1.0

    self.minRateThreePercentButton.rounded(
      color: self.viewModel.minRateType == 0 ? selectedColor : normalColor,
      width: self.viewModel.minRateType == 0 ? selectedWidth : normalWidth,
      radius: self.minRateThreePercentButton.frame.height / 2.0
    )

    self.minRateAnyRateButton.rounded(
      color: self.viewModel.minRateType == 1 ? selectedColor : normalColor,
      width: self.viewModel.minRateType == 1 ? selectedWidth : normalWidth,
      radius: self.minRateAnyRateButton.frame.height / 2.0
    )

    self.minRateCustomButton.rounded(
      color: self.viewModel.minRateType == 2 ? selectedColor : normalColor,
      width: self.viewModel.minRateType == 2 ? selectedWidth : normalWidth,
      radius: self.minRateCustomButton.frame.height / 2.0
    )

    self.minRateCustomTextField.isEnabled = self.viewModel.minRateType == 2
    if self.minRateCustomTextField.isEnabled == false {
      self.minRateCustomTextField.text = ""
    }

    switch self.viewModel.minRateType {
    case 0:
      self.viewModel.updateMinRateValue(
        type: 0,
        percent: 3.0,
        currentRate: self.viewModel.currentRate
      )
    case 1:
      let maxMinRatePercent: Double = self.viewModel.dataType == .pay ? 90.0 : 100.0
      self.viewModel.updateMinRateValue(
        type: 1,
        percent: maxMinRatePercent,
        currentRate: self.viewModel.currentRate
      )
    case 2:
      let val = self.viewModel.minRatePercent
      self.viewModel.updateMinRateValue(
        type: 2,
        percent: val,
        currentRate: self.viewModel.currentRate
      )
    default: break
    }

    self.stillProceedIfRateGoesDownByLabel.text = String(format: KWStringConfig.current.stillProceedIfRateGoesDownBy, "\(self.viewModel.sourceToken)-\(self.viewModel.destToken)")
    self.transactionRevertedDescLabel.text = String(
      format: KWStringConfig.current.transactionWillRevertIfRateLower,
      arguments: ["\(self.viewModel.sourceToken)-\(self.viewModel.destToken)", "\(self.viewModel.minRateString.prefix(12))", "\("\(self.viewModel.currentRate)".prefix(12))"])
    self.heightConstraintMinRateContainerView.constant = self.viewModel.minRateViewHeight
    self.layoutIfNeeded()
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt) {
    if self.viewModel == nil { return }
    self.viewModel.updateGasPrices(fast: fast, medium: medium, slow: slow)
    self.updateGasPriceUIs()
  }

  @discardableResult
  func updateHasMinRate(_ hasMinRate: Bool) -> Bool {
    if self.viewModel == nil { return false }
    if self.viewModel.hasMinRate == hasMinRate { return false }
    self.viewModel.updateHasMinRate(hasMinRate: hasMinRate)
    self.updateMinRateUIs()
    return true
  }

  func updateMinRate(percent: Double, currentRate: Double) {
    if self.viewModel == nil { return }
    if self.viewModel.minRateType == 2, self.viewModel.minRatePercent != percent {
      self.minRateCustomTextField.text = "\(percent)"
    }
    self.viewModel.updateMinRateValue(
      type: self.viewModel.minRateType,
      percent: percent,
      currentRate: currentRate
    )
    self.updateMinRateUIs()
  }

  @IBAction func displayViewButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    let isHidden = !self.viewModel.isViewHidden
    self.viewModel.updateViewHidden(isHidden: isHidden)
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .displayButtonPressed)
  }

  @IBAction func fastGasButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    self.viewModel.updateSelectedType(.fast)
    self.updateGasPriceUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast))
  }

  @IBAction func mediumGasButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    self.viewModel.updateSelectedType(.medium)
    self.updateGasPriceUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium))
  }

  @IBAction func slowGasButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    self.viewModel.updateSelectedType(.slow)
    self.updateGasPriceUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow))
  }

  @IBAction func threePercentButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    self.viewModel.updateMinRateValue(type: 0, percent: 3.0, currentRate: self.viewModel.currentRate)
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
  }

  @IBAction func anyRateButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    let maxMinRatePercent: Double = self.viewModel.dataType == .pay ? 90.0 : 100.0
    self.viewModel.updateMinRateValue(type: 1, percent: maxMinRatePercent, currentRate: self.viewModel.currentRate)
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: maxMinRatePercent))
  }

  @IBAction func customeRateButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    self.minRateCustomTextField.text = "3.0"
    self.minRateCustomTextField.isEnabled = true
    self.viewModel.updateMinRateValue(type: 2, percent: 3.0, currentRate: self.viewModel.currentRate)
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.displayViewButtonPressed(sender)
  }
}

extension KAdvancedSettingsView: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.removeGroupSeparator()
    let value: Double? = number.isEmpty ? 0 : Double(number)
    let maxMinRatePercent: Double = self.viewModel.dataType == .pay ? 90.0 : 100.0
    if let val = value, val >= 0, val <= maxMinRatePercent {
      textField.text = text
      self.viewModel.updateMinRateValue(type: 2, percent: val, currentRate: self.viewModel.currentRate)
      self.updateMinRateUIs()
      self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: val))
    }
    return false
  }
}
