//
//  KWSendRawTransactionRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import JSONRPCKit

struct KWSendRawTransactionRequest: JSONRPCKit.Request {
  typealias Response = String

  let signedData: String

  var method: String { return "eth_sendRawTransaction" }

  var parameters: Any? { return [self.signedData] }

  func response(from resultObject: Any) throws -> Response {
    if let response = resultObject as? Response {
      return response
    } else {
      throw KWCastError(actualValue: resultObject, expectedType: Response.self)
    }
  }
}
