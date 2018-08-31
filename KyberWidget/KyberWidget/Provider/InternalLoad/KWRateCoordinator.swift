//
//  KWRateCoordinator.swift
//  KyberWidget
//
//  Created by Manh Le on 31/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import Moya
import Result

public struct KWETHRate {
  let symbol: String // symbol
  let rate: Double

  init(dict: JSONDictionary) {
    self.symbol = dict["token_symbol"] as? String ?? ""
    self.rate = dict["rate_eth_now"] as? Double ?? 0.0
  }
}

public class KWRateCoordinator: NSObject {

  static public let shared = KWRateCoordinator()
  public var rates: [KWETHRate] = []

  public func fetchTrackerRates(env: KWEnvironment, completion: @escaping (Result<[KWETHRate], AnyError>) -> Void) {
    let provider = MoyaProvider<KWNetworkProvider>()
    provider.request(.getRates(env: env)) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        do {
          _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let rates = json.values.map({ return KWETHRate(dict: $0 as? JSONDictionary ?? [:]) })
          self.rates = rates
          completion(.success(rates))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}
