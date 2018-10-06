
// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KWMinAcceptableRatePopupViewModel {
  let minRate: String
  let symbol: String

  var titleAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: KWThemeConfig.current.minRateDescTextColor,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
    ]
  }

  var descAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: KWThemeConfig.current.minRateDescTextColor,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
    ]
  }

  var highlightedAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: KWThemeConfig.current.minRateDescTextColor,
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .bold),
    ]
  }

  init(minRate: String, symbol: String) {
    self.minRate = minRate
    self.symbol = symbol
  }

  var attributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "Min Acceptable Rate", attributes: self.titleAttributes))
    attributedString.append(NSAttributedString(string: "\n\nGuard yourself during volatile times by setting the lowest conversion rate you would accept for this transaction.\n", attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: "Setting a high value may result in a failed transaction and you would be charged gas fees.\n\n", attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: "Our recommended Min Acceptable Rate is ", attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: minRate, attributes: self.highlightedAttributes))
    attributedString.append(NSAttributedString(string: " \(symbol)", attributes: self.descAttributes))
    return attributedString
  }
}

class KWMinAcceptableRatePopupViewController: UIViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var desciptionLabel: UILabel!
  let viewModel: KWMinAcceptableRatePopupViewModel

  init(viewModel: KWMinAcceptableRatePopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KWMinAcceptableRatePopupViewController", bundle: Bundle.framework)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.desciptionLabel.attributedText = self.viewModel.attributedString
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    if sender.location(in: self.view).y <= self.containerView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
