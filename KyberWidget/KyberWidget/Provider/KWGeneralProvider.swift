//
//  KWGeneralProvider.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//


import BigInt
import JSONRPCKit
import APIKit
import BigInt
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

public class KWGeneralProvider: NSObject {

  var networkAddress: Address!
  var web3Swift: KWWeb3Swift!
  var network: KWEnvironment

  public init(
    network: KWEnvironment
    ) {
    self.network = network
    self.web3Swift = KWWeb3Swift(url: URL(string: network.customRPC?.endpoint ?? "")!)
    self.networkAddress = Address(string: network.customRPC?.networkAddress ?? "")!
    super.init()
    self.web3Swift.start()
  }

  // MARK: Balance
  public func getETHBalanace(for address: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      let batch = BatchFactory().create(KWBalanceRequest(address: address))
      let request = KWEtherServiceRequest(batch: batch, endpoint: self.network.endpoint)
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let balance):
            completion(.success(balance))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  public func getTokenBalance(for address: Address, contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getTokenBalanceEncodeData(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let batch = BatchFactory().create(KWCallRequest(to: contract.description, data: data))
        let request = KWEtherServiceRequest(
          batch: batch,
          endpoint: self.network.endpoint
        )
        DispatchQueue.global(qos: .background).async {
          Session.send(request) { [weak self] result in
            DispatchQueue.main.async {
              guard let `self` = self else { return }
              switch result {
              case .success(let balance):
                self.getTokenBalanceDecodeData(from: balance, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: Transaction count
  public func getTransactionCount(for address: String, completion: @escaping (Result<Int, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      let batch = BatchFactory().create(KWGetTransactionCountRequest(
        address: address,
        state: "latest"
      ))
      let request = KWEtherServiceRequest(batch: batch, endpoint: self.network.endpoint)
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let count):
            completion(.success(count))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  public func getAllowance(for token: KWTokenObject, address: Address, networkAddress: Address, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if token.isETH {
      // ETH no need to request for approval
      completion(.success(true))
      return
    }
    let tokenAddress: Address = Address(string: token.address)!
    self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        let callRequest = KWCallRequest(to: tokenAddress.description, data: data)
        let getAllowanceRequest = KWEtherServiceRequest(
          batch: BatchFactory().create(callRequest),
          endpoint: self.network.endpoint
        )
        DispatchQueue.global(qos: .background).async {
          Session.send(getAllowanceRequest) { [weak self] getAllowanceResult in
            DispatchQueue.main.async {
              guard let `self` = self else { return }
              switch getAllowanceResult {
              case .success(let data):
                self.getTokenAllowanceDecodeData(data, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  public func getExpectedRate(from: KWTokenObject, to: KWTokenObject, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let source: Address = Address(string: from.address)!
    let dest: Address = Address(string: to.address)!
    self.getExpectedRateEncodeData(source: source, dest: dest, amount: amount) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        let callRequest = KWCallRequest(to: self.networkAddress.description, data: data)
        let getRateRequest = KWEtherServiceRequest(
          batch: BatchFactory().create(callRequest),
          endpoint: self.network.endpoint
        )
        Session.send(getRateRequest) { [weak self] getRateResult in
          guard let `self` = self else { return }
          switch getRateResult {
          case .success(let rateData):
            self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  public func approve(token: KWTokenObject, account: Account, keystore: KWKeystore, networkAddress: Address, networkID: Int, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    self.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    self.getTransactionCount(for: account.address.description) { result in
      switch result {
      case .success(let resp):
        txCount = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }
      self.signTransactionData(forApproving: token, account: account, nonce: txCount, data: encodeData, keystore: keystore, networkID: networkID, completion: { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signData):
          self.sendSignedTransactionData(signData, completion: { sendResult in
            switch sendResult {
            case .success:
              completion(.success(txCount + 1))
            case .failure(let error):
              completion(.failure(error))
            }
          })
        case .failure(let error):
          completion(.failure(error))
        }
      })
    }
  }

  public func sendSignedTransactionData(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      let batch = BatchFactory().create(KWSendRawTransactionRequest(signedData: data.hexEncoded))
      let request = KWEtherServiceRequest(batch: batch, endpoint: self.network.endpoint)
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let transactionID):
            completion(.success(transactionID))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  public func getUserCapInWei(for address: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getUserCapInWeiEncode(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let callReq = KWCallRequest(
          to: self.networkAddress.description,
          data: data
        )
        let ethService = KWEtherServiceRequest(
          batch: BatchFactory().create(callReq),
          endpoint: self.network.endpoint
        )
        DispatchQueue.global(qos: .background).async {
          Session.send(ethService) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let resp):
                self.getUserCapInWeiDecode(from: resp, completion: { decodeResult in
                  switch decodeResult {
                  case .success(let value):
                    completion(.success(value))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: Sign transaction
extension KWGeneralProvider {
  private func signTransactionData(forApproving token: KWTokenObject, account: Account, nonce: Int, data: Data, keystore: KWKeystore, networkID: Int, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction = KWDraftTransaction(
      value: BigInt(0),
      account: account,
      to: Address(string: token.address),
      nonce: nonce,
      data: data,
      gasPrice: KWGasConfiguration.gasPriceFast,
      gasLimit: KWGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: networkID
    )
    let signResult = keystore.signTransaction(transaction: signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }
}

// MARK: KWWeb3Swift Encoding
extension KWGeneralProvider {
  fileprivate func getUserCapInWeiEncode(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KWGetUserCapInWeiEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenBalanceEncodeData(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KWGetTokenBalanceEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getSendApproveERC20TokenEncodeData(networkAddress: Address, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KWSendApproveTokenEncode(
      address: networkAddress.description,
      value: BigInt(2).power(255).description
    )
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceEncodeData(for address: Address, networkAddress: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KWGetTokenAllowanceEndcode(
      ownerAddress: address,
      spenderAddress: networkAddress
    )
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getExpectedRateEncodeData(source: Address, dest: Address, amount: BigInt, completion: @escaping (Result<String, AnyError>) -> Void) {
    let encodeRequest = KWGetExpectedRateEncode(source: source, dest: dest, amount: amount)
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: KWWeb3Swift Decoding
extension KWGeneralProvider {
  fileprivate func getUserCapInWeiDecode(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let request = KWGetUserCapInWeiDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt(0)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func getTokenBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let request = KWGetTokenBalanceDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if data == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(false))
      return
    }
    let decodeRequest = KWGetTokenAllowanceDecode(data: data)
    self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(!remain.isZero))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getExpectedRateDecodeData(rateData: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    //TODO (Mike): Currently decoding is always return invalid return type even though the response type is correct
    let decodeRequest = KWGetExpectedRateDecode(data: rateData)
    self.web3Swift.request(request: decodeRequest, completion: { (result) in
      switch result {
      case .success(let decodeData):
        let expectedRate = decodeData["expectedRate"] ?? ""
        let slippageRate = decodeData["slippageRate"] ?? ""
        completion(.success((BigInt(expectedRate) ?? BigInt(0), BigInt(slippageRate) ?? BigInt(0))))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          // Temporary fix for expected rate request
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            if let expectedRate = json["expectedRate"] as? String, let slippageRate = json["slippageRate"] as? String {
              completion(.success((BigInt(expectedRate) ?? BigInt(0), BigInt(slippageRate) ?? BigInt(0))))
              return
            }
          }
        }
        completion(.failure(AnyError(error)))
      }
    })
  }
}
