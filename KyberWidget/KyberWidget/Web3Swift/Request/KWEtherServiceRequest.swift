//
//  KWEtherServiceRequest.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import APIKit
import JSONRPCKit

struct KWEtherServiceRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
  typealias Response = Batch.Responses

  let batch: Batch
  let endpoint: String

  var baseURL: URL { return URL(string: endpoint)! }
  var method: HTTPMethod { return .post }
  var path: String { return "/" }
  var parameters: Any? { return batch.requestObject }

  func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
    return try self.batch.responses(from: object)
  }
}
