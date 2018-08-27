// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KWSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
  }

  func updateCell(with token: KWTokenObject, balance: BigInt?) {
    self.iconImageView.setTokenImage(token: token)
    self.tokenSymbolLabel.text = token.symbol
    self.tokenNameLabel.text = token.name
    let balText: String = balance?.string(
      decimals: token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: 6
      ) ?? ""
    self.balanceLabel.text = balText
    self.layoutIfNeeded()
  }
}
