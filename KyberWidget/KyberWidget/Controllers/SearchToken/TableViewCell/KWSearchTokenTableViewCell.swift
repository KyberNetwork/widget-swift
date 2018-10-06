// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KWSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenSymbolLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
  }

  func updateCell(with token: KWTokenObject) {
    self.iconImageView.setTokenImage(token: token)
    self.tokenSymbolLabel.text = token.symbol
    self.tokenNameLabel.text = token.name
    self.layoutIfNeeded()
  }
}
