//
//  KWThemeConfig.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit

public class KWStringConfig: NSObject {
  public static let current = KWStringConfig()

  public var payment: String = "Pay"
  public var swap: String = "Swap"
  public var buy: String = "Buy"
  public var importWallet: String = "Import Wallet"
  public var confirm: String = "Confirm"

  public var youAreAboutToPay: String = "You are about to pay"
  public var youAreAboutToBuy: String = "You are about to buy"
  public var address: String = "Address"
  public var amount: String = "Amount"
  public var productName: String = "Product Name"
  public var payWith: String = "PAY WITH"
  public var swapUppercased: String = "SWAP"
  public var estimateDestAmount: String = "Estimate dest amount"

  public var gasFee: String = "GAS fee"
  public var minAcceptableRate: String = "Min Acceptable Rate"

  public var agreeTo: String = "Agree to"
  public var termsAndConditions: String = "Terms & Conditions"
  public var next: String = "Next"

  public var unlock: String = "Unlock"
  public var unlockWallet: String = "Unlock Wallet"
  public var changeWallet: String = "Change wallet?"
  public var search: String = "Search"
  public var privateKey: String = "Private Key"
  public var seeds: String = "Seeds"
  public var importYourJSONFile: String = "Import JSON File"

  public var enterPasswordDescrypt: String = "Enter Password Descrypt"
  public var enterPrivateKey: String = "Enter private key"
  public var enterSeeds: String = "Enter seeds"
  public var cancel: String = "Cancel"

  public var to: String = "To"

  public var addressToPay: String = "Address to pay"
  public var amountToPayUppercased: String = "Amount to pay".uppercased()
  public var amountToBuyUppercased: String = "Amount to buy".uppercased()
}

public class KWThemeConfig: NSObject {

  public static let current = KWThemeConfig()

  public var navigationBarBackgroundColor: UIColor = UIColor.Kyber.background
  public var navigationBarTintColor: UIColor = UIColor.white

  public var importTypeButtonColor: UIColor = UIColor.Kyber.segment
  public var importTextFieldColor: UIColor = UIColor.Kyber.black
  public var importButtonColor: UIColor = UIColor.Kyber.background
  public var importButtonTitleColor: UIColor = UIColor.white

  public var payTextFieldColor: UIColor = UIColor.Kyber.background
  public var payReceiveAmountColor: UIColor = UIColor.Kyber.grey
  public var payBalanceTextColor: UIColor = UIColor.Kyber.segment
  public var payBalanceValueColor: UIColor = UIColor.Kyber.black
  public var payRateTextColor: UIColor = UIColor.Kyber.segment
  public var payRateValueColor: UIColor = UIColor.Kyber.black
  public var payGasSegmentTintColor: UIColor = UIColor.Kyber.background
  public var payGasTextFieldColor: UIColor = UIColor.Kyber.background
  public var payTransactionFeeColor: UIColor = UIColor.Kyber.segment
  public var payMinRateValueColor: UIColor = UIColor.Kyber.background
  public var payMinRateSliderMinTrackColor: UIColor = UIColor.Kyber.shamrock
  public var payMinRateSliderMaxTrackColor: UIColor = UIColor.Kyber.shamrock.withAlphaComponent(0.5)
  public var payMinRateThumbTintColor: UIColor = UIColor.Kyber.background
  public var payMinRatePercentColor: UIColor = UIColor.Kyber.shamrock

  public var amountTextFieldEnable: UIColor = UIColor.Kyber.shamrock
  public var amountTextFieldDisable: UIColor = UIColor.Kyber.black

  public var confirmSwapFromAmountColor: UIColor = UIColor.Kyber.black
  public var confirmSwapToAmountColor: UIColor = UIColor.Kyber.black
  public var confirmSwapExpectedRateColor: UIColor = UIColor.Kyber.black
  public var confirmToTextColor: UIColor = UIColor.Kyber.shamrock

  public var confirmAddressToPayTextColor: UIColor = UIColor.Kyber.segment
  public var confirmAddressTextColor: UIColor = UIColor(red: 102, green: 102, blue: 102)
  public var confirmAmountToPayTextColor: UIColor = UIColor.Kyber.segment
  public var confirmPayFromAmountColor: UIColor = UIColor.Kyber.background
  public var confirmPayReceivedAmountColor: UIColor = UIColor.Kyber.black

  public var actionButtonNormalBackgroundColor: UIColor = UIColor.Kyber.background
  public var actionButtonDisableBackgroundColor: UIColor = UIColor(red: 225, green: 225, blue: 225)
  public var minRateDescTextColor: UIColor = UIColor.Kyber.minRate

  public var activeStepBackgroundColor: UIColor = UIColor.Kyber.background
  public var inactiveBackgroundColor: UIColor = UIColor(red: 225, green: 225, blue: 225)

  public var doneIcon: UIImage? = UIImage(named: "done_white_icon", in: Bundle.framework, compatibleWith: nil)
  public override init() { }
}
