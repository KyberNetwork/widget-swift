//
//  KWGasCoordinator.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//


import BigInt
import Moya
import Result

class KWGasCoordinator {

  var mediumGas: BigInt = KWGasConfiguration.gasPriceMedium
  var slowGas: BigInt = KWGasConfiguration.gasPriceSlow
  var fastGas: BigInt = KWGasConfiguration.gasPriceFast

  static let shared = KWGasCoordinator()
  let provider = MoyaProvider<KWNetworkProvider>()

  func getKNCachedGasPrice(completion: @escaping () -> Void) {
    self.performFetchRequest(service: .getGasPrice) { result in
      switch result {
      case .success(let json):
        self.updateGasPrice(dataJSON: json)
      default: break
      }
      completion()
    }
  }

  private func performFetchRequest(service: KWNetworkProvider, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    self.provider.request(service) { (result) in
      switch result {
      case .success(let response):
        do {
          _ = try response.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try response.mapJSON() as? JSONDictionary ?? [:]
          completion(.success(json))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func updateGasPrice(dataJSON: JSONDictionary) {
    guard let data = dataJSON["data"] as? JSONDictionary else { return }
    let stringSlow: String = data["low"] as? String ?? ""
    self.slowGas = stringSlow.toBigInt(units: .gwei) ?? self.slowGas
    let stringMedium: String = data["standard"] as? String ?? ""
    self.mediumGas = stringMedium.toBigInt(units: .gwei) ?? self.mediumGas
    let stringFast: String = data["fast"] as? String ?? ""
    self.fastGas = stringFast.toBigInt(units: .gwei) ?? self.fastGas
  }
}
