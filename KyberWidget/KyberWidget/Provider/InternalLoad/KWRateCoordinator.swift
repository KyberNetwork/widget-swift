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

public struct KWRate {
  let from: String
  let to: String
  let rate: Double

  init(dict: JSONDictionary) {
    self.from = dict["source"] as? String ?? ""
    self.to = dict["dest"] as? String ?? ""
    self.rate = {
      let rateString = dict["rate"] as? String ?? ""
      let rateDouble = Double(rateString) ?? 0.0
      return rateDouble / pow(10.0, 18.0)
    }()
  }
}

public class KWRateCoordinator: NSObject {

  static public let shared = KWRateCoordinator()
  public var rates: [KWRate] = []

  public func fetchTrackerRates(env: KWEnvironment, completion: @escaping (Result<[KWRate], AnyError>) -> Void) {
    let provider = MoyaProvider<KWNetworkProvider>()
    provider.request(.getRates(env: env)) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        do {
          _ = try data.filterSuccessfulStatusCodes()
          let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let data = json["data"] as? [JSONDictionary] ?? []
          let rates = data.map({ return KWRate(dict: $0) })
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
