//
//  KWEstimateGasLimitRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import JSONRPCKit
import TrustKeystore
import TrustCore
import BigInt

struct KWEstimateGasLimitRequest: JSONRPCKit.Request {
  typealias Response = String

  let from: String
  let to: String?
  let value: BigInt
  let data: Data
  let gasPrice: BigInt

  var method: String { return "eth_estimateGas" }

  var parameters: Any? {
    return [
      [
        "from": from.lowercased(),
        "to": to?.lowercased() ?? "0x",
        "gasPrice": gasPrice.hexEncoded,
        "value": value.hexEncoded,
        "data": data.hexEncoded,
      ],
    ]
  }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? Response {
      return response
    } else {
      throw KWCastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
