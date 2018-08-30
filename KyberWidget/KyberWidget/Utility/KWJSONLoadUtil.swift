//
//  KWJSONLoadUtil.swift
//  KyberWidget
//
//  Created by Manh Le on 27/8/18.
//  Copyright © 2018 kyber.network. All rights reserved.
//

import Foundation

public typealias JSONDictionary = [String: Any]

public class KWJSONLoadUtil {

  static let shared = KWJSONLoadUtil()

  static public func loadListSupportedTokensFromJSONFile(env: KWEnvironment) -> [KWTokenObject] {
    guard let json = KWJSONLoadUtil.jsonDataFromFile(with: env.configFileName) else { return [] }
    guard let tokensJSON = json["tokens"] as? JSONDictionary else { return [] }
    let tokens = tokensJSON.values.map({ return KWTokenObject(localDict: $0 as? JSONDictionary ?? [:]) })
    return tokens
  }

  static public func jsonDataFromFile(with name: String) -> JSONDictionary? {
    guard let bundle = Bundle.framework else {
      print("---> Error: Bundle not found")
      return nil
    }
    guard let path = bundle.path(forResource: name, ofType: "json") else {
      print("---> Error: File not found with name \(name)")
      return nil
    }
    let urlPath = URL(fileURLWithPath: path)
    var data: Data? = nil
    do {
      data = try Data(contentsOf: urlPath)
    } catch let error {
      print("---> Error: Get data from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    guard let jsonData = data else {
      print("---> Error: Can not cast data from file \(name) to json")
      return nil
    }
    do {
      let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
      // TODO: Data might be an array
      if let objc = json as? JSONDictionary { return objc }
    } catch let error {
      print("---> Error: Cast json from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    return nil
  }
}
