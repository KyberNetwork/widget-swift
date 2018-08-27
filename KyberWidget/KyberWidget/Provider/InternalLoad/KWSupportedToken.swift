//
//  KWSupportedToken.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//


import UIKit
import Moya
import Result

public class KWSupportedToken: NSObject {

  static public let shared = KWSupportedToken()

  public func fetchTrackerSupportedTokens(network: KWEnvironment, completion: @escaping (Result<[KWTokenObject], AnyError>) -> Void) {
    print("---- Supported Tokens: Start fetching data ----")
    let provider = MoyaProvider<KWNetworkProvider>()
    DispatchQueue.global(qos: .background).async {
      provider.request(.getSupportedTokens(env: network)) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              let jsonArr: [JSONDictionary] = try response.mapJSON(failsOnEmptyData: false) as? [JSONDictionary] ?? []
              let tokenObjects = jsonArr.map({ return KWTokenObject(trackerDict: $0) })
              completion(.success(tokenObjects))
              print("---- Supported Tokens: Load successfully")
            } catch let error {
              print("---- Supported Tokens: Cast reponse failed with error: \(error.localizedDescription) ----")
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
            print("---- Supported Tokens: Failed with error: \(error.localizedDescription)")
          }
        }
      }
    }
  }
}
