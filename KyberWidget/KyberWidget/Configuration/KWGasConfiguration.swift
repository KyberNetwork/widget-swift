//
//  KWGasConfiguration.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt

public struct KWGasConfiguration {
  static let digixGasLimitDefault = BigInt(770_000)
  static let exchangeTokensGasLimitDefault = BigInt(700_000)
  static let exchangeETHTokenGasLimitDefault = BigInt(350_000)
  static let payTransferTokenGasLimitDefault = BigInt(200_000)
  static let approveTokenGasLimitDefault = BigInt(100_000)
  static let transferTokenGasLimitDefault = BigInt(60_000)
  static let transferETHGasLimitDefault = BigInt(21_000)

  static let daiGasLimitDefault = BigInt(450_000)
  static let makerGasLimitDefault = BigInt(400_000)
  static let propyGasLimitDefault = BigInt(500_000)
  static let promotionTokenGasLimitDefault = BigInt(380_000)

  static let gasPriceFast = BigInt(15) * BigInt(10).power(9)
  static let gasPriceMedium = BigInt(10) * BigInt(10).power(9)
  static let gasPriceSlow = BigInt(5) * BigInt(10).power(9)
  static let gasPriceMax = BigInt(50) * BigInt(10).power(9)

  static func calculateGasLimit(from: KWTokenObject, to: KWTokenObject, isPay: Bool) -> BigInt {
    if from == to {
      // normal transfer
      if isPay { return payTransferTokenGasLimitDefault }
      return calculateDefaultGasLimitTransfer(token: from)
    }
    let gasSrcToETH: BigInt = {
      if from.isETH { return BigInt(0) }
      if from.isDGX { return digixGasLimitDefault }
      if from.isDAI { return daiGasLimitDefault }
      if from.isMKR { return makerGasLimitDefault }
      if from.isPRO { return propyGasLimitDefault }
      if from.isPT { return promotionTokenGasLimitDefault }
      return exchangeETHTokenGasLimitDefault
    }()
    let gasETHToDest: BigInt = {
      if to.isETH { return BigInt(0) }
      if to.isDGX { return digixGasLimitDefault }
      if to.isDAI { return daiGasLimitDefault }
      if to.isMKR { return makerGasLimitDefault }
      if to.isPRO { return propyGasLimitDefault }
      if to.isPT { return promotionTokenGasLimitDefault }
      return exchangeETHTokenGasLimitDefault
    }()
    return gasSrcToETH + gasETHToDest
  }

  static func calculateDefaultGasLimitTransfer(token: KWTokenObject) -> BigInt {
    if token.isETH { return transferETHGasLimitDefault }
    if token.isDGX { return digixGasLimitDefault }
    if token.isDAI { return daiGasLimitDefault }
    if token.isMKR { return makerGasLimitDefault }
    if token.isPRO { return propyGasLimitDefault }
    if token.isPT { return promotionTokenGasLimitDefault }
    return transferTokenGasLimitDefault
  }
}
