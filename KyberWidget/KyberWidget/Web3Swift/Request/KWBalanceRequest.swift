//
//  KWBalanceRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt
import Foundation
import JSONRPCKit

struct KWBalanceRequest: JSONRPCKit.Request {
  typealias Response = BigInt

  let address: String

  var method: String { return "eth_getBalance" }
  var parameters: Any? { return [self.address, "latest"] }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? String, let value = BigInt(response.drop0x, radix: 16) {
      return value
    } else {
      throw KWCastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
