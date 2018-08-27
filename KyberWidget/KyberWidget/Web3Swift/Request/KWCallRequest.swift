//
//  KWCallRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import JSONRPCKit

struct KWCallRequest: JSONRPCKit.Request {
  typealias Response = String

  let to: String
  let data: String

  var method: String { return "eth_call" }

  var parameters: Any? {
    return [["to": self.to, "data": self.data], "latest"]
  }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? Response {
      return response
    } else {
      throw KWCastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
