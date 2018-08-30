//
//  KWWeb3Swift.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation
import WebKit
import JavaScriptKit
import Result
import JavaScriptCore

protocol KWWeb3Request {
  associatedtype Response: Decodable
  var command: String { get }
}

struct KWCastError<ExpectedType>: Error {
  let actualValue: Any
  let expectedType: ExpectedType.Type
}

class KWWeb3Swift: NSObject {

  let webView = WKWebView()
  let url: URL
  var isLoaded = false

  init(url: URL) { self.url = url }

  func start() {
    self.webView.navigationDelegate = self
    self.loadWeb3()
  }

  private func loadWeb3() {
    guard let bundle = Bundle.framework else { return }
    if let url = bundle.url(forResource: "index", withExtension: "html") {
      webView.load(URLRequest(url: url))
    }
  }

  func request<T: KWWeb3Request>(request: T, completion: @escaping (Result<T.Response, AnyError>) -> Void) {
    guard isLoaded else {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
        self.request(request: request, completion: completion)
      }
      return
    }
    JSScript<T.Response>(request.command).evaluate(in: webView) { result in
      switch result {
      case .success(let result):
        completion(.success(result))
      case .failure(let error):
        NSLog("script error \(error)")
        completion(.failure(AnyError(error)))
      }
    }
  }
}

extension KWWeb3Swift: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    self.isLoaded = true
    JSVariable<String>("web3.setProvider(new web3.providers.HttpProvider('\(url.absoluteString))").evaluate(in: webView) { result in }
  }
}
