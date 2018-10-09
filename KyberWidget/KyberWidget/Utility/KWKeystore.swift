//
//  KWKeystore.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import UIKit
import Foundation
import Security
import Result
import BigInt
import TrustCore
import CryptoSwift
import TrustKeystore
import KeychainSwift

public enum KWKeystoreError: LocalizedError {
  case failedToImport
  case failedToDelete
  case failedToSign

  public var errorDescription: String? {
    switch self {
    case .failedToSign:
      return "Failed to sign transaction"
    case .failedToDelete:
      return "Can not delete the account"
    case .failedToImport:
      return "Can not import the wallet"
    }
  }
}

public enum KWImportType {
  case keystore(string: String, password: String)
  case privateKey(string: String)
  case mnemonic(words: [String], password: String)
}

public class KWKeystore {
  private let dataDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

  private let keychain: KeychainSwift
  let keystore: KeyStore
  let keysDirectory: URL

  public init() throws {
    self.keychain = KeychainSwift(keyPrefix: "kyberpayios")
    self.keychain.synchronizable = false
    
    self.keysDirectory = URL(fileURLWithPath: self.dataDirectory + "/kpkeystore")
    self.keystore = try KeyStore(keyDirectory: self.keysDirectory)
  }

  public var accounts: [Account] {
    return self.keystore.accounts
  }

  public var account: Account? {
    return self.accounts.first
  }

  public func removeAllAccounts(completion: @escaping () -> Void) {
    guard let account = self.account else {
      completion()
      return
    }
    self.delete(account: account) { _ in
      completion()
    }
  }
  public func importWallet(type: KWImportType, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {
    let newPassword = self.generateRandomString(bytesCount: 32)
    switch type {
    case .keystore(let string, let password):
      self.importKeystore(value: string, password: password, newPassword: newPassword, completion: completion)
    case .privateKey(let string):
      self.importPrivateKey(string, newPassword: newPassword, completion: completion)
    case .mnemonic(let words, let password):
      self.importMnemonic(words, password: password, newPassword: newPassword, completion: completion)
    }
  }

  public func delete(account: Account) -> Result<Void, KWKeystoreError> {
    print("Delete account: Start \(Date().description)")
    guard let password = self.keychain.get(account.address.description)?.lowercased() else {
      return .failure(.failedToDelete)
    }
    print("Delete account: Got Password \(Date().description)")
    do {
      try self.keystore.delete(account: account, password: password)
      print("Delete account: Done deleting \(Date().description)")
      return .success(())
    } catch {
      return .failure(.failedToDelete)
    }
  }

  public func delete(account: Account, completion: @escaping (Result<Void, KWKeystoreError>) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      let result = self.delete(account: account)
      DispatchQueue.main.async {
        completion(result)
      }
    }
  }
  

  public func signTransaction(transaction: KWDraftTransaction) -> Result<Data, KWKeystoreError> {
    let account = transaction.account
    print("Signing transaction: Start \(Date().description)")
    guard let password = self.keychain.get(transaction.account.address.description) else {
      return .failure(KWKeystoreError.failedToSign)
    }
    print("Signing transaction: Got password \(Date().description)")
    do {
      let hash = self.hash(transaction: transaction)
      print("Signing transaction: Got Hash")
      let signature = try self.keystore.signHash(hash, account: account, password: password)
      print("Signing transaction: Got Signature \(Date().description)")
      let (r, s, v) = self.values(transaction: transaction, signature: signature)
      print("Signing transaction: Got r, s, v \(Date().description)")
      let element = [
        transaction.nonce,
        transaction.gasPrice,
        transaction.gasLimit,
        transaction.to?.data ?? Data(),
        transaction.value,
        transaction.data,
        v,
        r,
        s,
      ] as [Any]
      guard let data = RLP.encode(element) else {
        return .failure(KWKeystoreError.failedToSign)
      }
      print("Signing transaction: Got data \(Date().description)")
      return .success(data)
    } catch {
      return .failure(KWKeystoreError.failedToSign)
    }
  }
}

// MARK: Private helper functions
extension KWKeystore {
  func importKeystore(value: String, password: String, newPassword: String, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      let result = self.importKeystore(value: value, password: password, newPassword: newPassword)
      DispatchQueue.main.async {
        switch result {
        case .success(let account):
          completion(.success(account))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }

  func importKeystore(value: String, password: String, newPassword: String) -> Result<Account, KWKeystoreError> {
    print("Importing keystore: Start \(Date().description)")
    guard let data = value.data(using: .utf8) else {
      return (.failure(.failedToImport))
    }
    do {
      print("Importing keystore: Got data \(Date().description)")
      let account = try self.keystore.import(json: data, password: password, newPassword: newPassword)
      print("Importing keystore: Imported \(Date().description)")
      let _ = self.setPassword(newPassword, for: account)
      print("Importing keystore: Done \(Date().description)")
      return .success(account)
    } catch {
      return .failure(.failedToImport)
    }
  }

  private func importPrivateKey(_ privateKey: String, newPassword: String, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {
    print("Importing private key: creating keystore \(Date().description)")
    DispatchQueue.global(qos: .userInitiated).async {
      self.keystore(for: privateKey, password: newPassword, completion: { result in
        DispatchQueue.main.async {
          print("Importing private key: Done creating keystore \(Date().description)")
          switch result {
          case .success(let resp):
            self.importKeystore(value: resp, password: newPassword, newPassword: newPassword, completion: completion)
          case .failure(let error):
            completion(.failure(error))
          }
        }
      })
    }
  }

  func keystore(for privateKey: String, password: String, completion: @escaping (Result<String, KWKeystoreError>) -> Void) {
    print("Keystore from private key: Start at \(Date().description)")
    guard let data = Data(hexString: privateKey) else {
      completion(.failure(.failedToImport))
      return
    }
    print("Keystore from private key: Got data \(Date().description)")
    do {
      let key = try KeystoreKey(password: password, key: data)
      print("Keystore from private key: Got Key \(Date().description)")
      let data = try JSONEncoder().encode(key)
      print("Keystore from private key: Got data \(Date().description)")
      let dict = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
      print("Keystore from private key: Got dict \(Date().description)")
      guard let keystore = dict.jsonString else {
        completion(.failure(.failedToImport))
        return
      }
      print("Keystore from private key: Done \(Date().description)")
      completion(.success(keystore))
    } catch {
      completion(.failure(.failedToImport))
      return
    }
  }

  private func importMnemonic(_ words: [String], password: String, newPassword: String, completion: @escaping (Result<Account, KWKeystoreError>) -> Void) {
    print("Importing mnemonic \(Date().description)")
    DispatchQueue.global(qos: .userInitiated).async {
      let key = words.joined(separator: " ")
      do {
        let account = try self.keystore.import(mnemonic: key, passphrase: password, encryptPassword: newPassword)
        _ = self.setPassword(newPassword, for: account)
        DispatchQueue.main.async {
          print("Done importing mnemonic \(Date().description)")
          completion(.success(account))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(.failedToImport))
        }
      }
    }
  }

  private func generateRandomString(bytesCount: Int) -> String {
    var randomBytes = [UInt8](repeating: 0, count: bytesCount)
    let _ = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
    return randomBytes.map({ String(format: "%02hhx", $0) }).joined(separator: "")
  }

  private func setPassword(_ password: String, for account: Account) {
    _ = self.keychain.set(
      password,
      forKey: account.address.description,
      withAccess: .accessibleWhenUnlockedThisDeviceOnly
    )
  }

  private func hash(transaction: KWDraftTransaction) -> Data {
    let element = [
      transaction.nonce,
      transaction.gasPrice,
      transaction.gasLimit,
      transaction.to?.data ?? Data(),
      transaction.value,
      transaction.data,
      transaction.chainID, 0, 0,
    ] as [Any]
    let sha3 = SHA3(variant: .keccak256)
    let data = RLP.encode(element)!
    return Data(bytes: sha3.calculate(for: data.bytes))
  }

  private func values(transaction: KWDraftTransaction, signature: Data) -> (r: BigInt, s: BigInt, v: BigInt) {
    // FIX: Crash on iOS 10
    let r = BigInt(sign: .plus, magnitude: BigUInt(Data(signature[..<32])))
    let s = BigInt(sign: .plus, magnitude: BigUInt(Data(signature[32..<64])))
    let v = BigInt(sign: .plus, magnitude: BigUInt(Data(bytes: [signature[64] + 27])))

    let newV: BigInt
    let chainID: BigInt = BigInt(transaction.chainID)
    if chainID != 0 {
      newV = BigInt(signature[64]) + 35 + chainID + chainID
    } else {
      newV = v
    }
    return (r, s, newV)
  }
}
