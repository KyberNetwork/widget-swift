// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KWSearchTokenViewEvent {
  case cancel
  case select(token: KWTokenObject)
}

protocol KWSearchTokenViewControllerDelegate: class {
  func searchTokenViewController(_ controller: KWSearchTokenViewController, run event: KWSearchTokenViewEvent)
}

class KWSearchTokenViewModel {

  var supportedTokens: [KWTokenObject] = []
  let pinnedTokens: [String]
  var searchedText: String = "" {
    didSet {
      self.updateDisplayedTokens()
    }
  }
  var displayedTokens: [KWTokenObject] = []

  init(supportedTokens: [KWTokenObject], pinnedTokens: [String]) {
    self.supportedTokens = supportedTokens.sorted(by: { return $0.symbol < $1.symbol })
    self.pinnedTokens = pinnedTokens
    self.searchedText = ""
    self.displayedTokens = self.supportedTokens
  }

  var isNoMatchingTokenHidden: Bool { return !self.displayedTokens.isEmpty }

  func updateDisplayedTokens() {
    self.displayedTokens = {
      if self.searchedText == "" {
        return self.supportedTokens
      }
      return self.supportedTokens.filter({ ($0.symbol + " " + $0.name).lowercased().contains(self.searchedText.lowercased()) })
    }()
    self.displayedTokens.sort { (token0, token1) -> Bool in
      if self.pinnedTokens.contains(token0.symbol) { return true }
      if self.pinnedTokens.contains(token1.symbol) { return true }
      return token0.symbol < token1.symbol
    }
  }

  func updateListSupportedTokens(_ tokens: [KWTokenObject]) {
    self.supportedTokens = tokens.sorted(by: { return $0.symbol < $1.symbol })
    self.updateDisplayedTokens()
  }

  func updateSupportedTokens(_ tokens: [KWTokenObject]) {
    self.supportedTokens = tokens
    self.updateDisplayedTokens()
  }
}

class KWSearchTokenViewController: UIViewController {

  fileprivate let kSearchTokenTableViewCellID: String = "CellID"

  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tokensTableView: UITableView!
  @IBOutlet weak var noMatchingTokensLabel: UILabel!
  @IBOutlet weak var tableViewBottomPaddingConstraint: NSLayoutConstraint!

  fileprivate var viewModel: KWSearchTokenViewModel
  weak var delegate: KWSearchTokenViewControllerDelegate?

  init(viewModel: KWSearchTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KWSearchTokenViewController", bundle: Bundle.framework)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationItem.title = "Search token"

    self.searchTextField.text = ""
    self.searchTextDidChange("")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  fileprivate func setupUI() {
    let image = UIImage(named: "back_white_icon", in: Bundle.framework, compatibleWith: nil)
    let leftItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.leftButtonPressed(_:)))
    leftItem.tintColor = .white
    self.navigationItem.leftBarButtonItem = leftItem
    self.navigationItem.leftBarButtonItem?.tintColor = KWThemeConfig.current.navigationBarTintColor

    self.searchTextField.delegate = self
    self.searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: self.searchTextField.frame.height))
    self.searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: self.searchTextField.frame.height))
    self.searchTextField.rounded(
      color: UIColor(red: 231, green: 231, blue: 231),
      width: 1,
      radius: 5.0
    )

    let nib = UINib(nibName: "KWSearchTokenTableViewCell", bundle: Bundle.framework)
    self.tokensTableView.register(nib, forCellReuseIdentifier: kSearchTokenTableViewCellID)
    self.tokensTableView.rowHeight = 46
    self.tokensTableView.delegate = self
    self.tokensTableView.dataSource = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.keyboardDidShow(_:)),
      name: UIResponder.keyboardDidShowNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.keyboardDidHide(_:)),
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )
  }

  func coordinatorUpdateSupportedTokens(_ tokens: [KWTokenObject]) {
    self.viewModel.updateSupportedTokens(tokens)
    self.tokensTableView.reloadData()
  }

  fileprivate func searchTextDidChange(_ newText: String) {
    self.viewModel.searchedText = newText
    self.updateUIDisplayedDataDidChange()
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.delegate?.searchTokenViewController(self, run: .cancel)
  }

  fileprivate func updateUIDisplayedDataDidChange() {
    self.noMatchingTokensLabel.isHidden = self.viewModel.isNoMatchingTokenHidden
    self.tokensTableView.isHidden = !self.viewModel.isNoMatchingTokenHidden
    self.tokensTableView.reloadData()
  }

  func updateListSupportedTokens(_ tokens: [KWTokenObject]) {
    self.viewModel.updateListSupportedTokens(tokens)
    self.updateUIDisplayedDataDidChange()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.searchTokenViewController(self, run: .cancel)
  }

  @objc func keyboardDidShow(_ sender: Notification) {
    if let keyboardSize = (sender.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      UIView.animate(
      withDuration: 0.25) {
        self.tableViewBottomPaddingConstraint.constant = keyboardSize.height
        self.view.updateConstraints()
      }
    }
  }

  @objc func keyboardDidHide(_ sender: Notification) {
    UIView.animate(
    withDuration: 0.25) {
      self.tableViewBottomPaddingConstraint.constant = 0
      self.view.updateConstraints()
    }
  }
}

extension KWSearchTokenViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.searchTextDidChange(text)
    return false
  }
}

extension KWSearchTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.row < self.viewModel.displayedTokens.count {
      let token = self.viewModel.displayedTokens[indexPath.row]
      self.delegate?.searchTokenViewController(self, run: .select(token: token))
    }
  }
}

extension KWSearchTokenViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.displayedTokens.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kSearchTokenTableViewCellID, for: indexPath) as! KWSearchTokenTableViewCell
    let token = self.viewModel.displayedTokens[indexPath.row]
    cell.updateCell(with: token)
    return cell
  }
}
