//
//  KWGetTransactionCountRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import BigInt
import Foundation
import JSONRPCKit

struct KWGetTransactionCountRequest: JSONRPCKit.Request {
  typealias Response = Int

  let address: String
  let state: String

  var method: String { return "eth_getTransactionCount" }
  var parameters: Any? { return [self.address, self.state] }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? String {
      return BigInt(response.drop0x, radix: 16).flatMap({ numericCast($0) }) ?? 0
    } else {
      throw KWCastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
