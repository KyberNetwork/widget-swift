//
//  KWEstimateGasRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import JSONRPCKit
import TrustCore
import BigInt

struct KWEstimateGasRequest: JSONRPCKit.Request {
  typealias Response = String

  let from: Address
  let to: Address?
  let value: BigInt
  let data: Data

  var method: String { return "eth_estimateGas" }

  var parameters: Any? {
    return [
      [
        "from": self.from.description,
        "to": self.to?.description ?? "",
        // Mike: Temp fix for estimate gas, no value needed
        // "value": value.description.hexEncoded,
        "data": self.data.hexEncoded,
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
