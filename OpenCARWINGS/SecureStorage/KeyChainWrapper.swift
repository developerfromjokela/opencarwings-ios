//
//  KeyChainWrapper.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation
import SwiftUI
import KeychainAccess

/// Keychain settings shared by the app, the share extension and the widget.
///
/// The access group is resolved at runtime from `AppIdentifierPrefix`, which Xcode
/// substitutes into every target's Info.plist with the prefix of the signing team, so
/// no team identifier has to be hardcoded. Builds without a provisioning profile (the
/// simulator) leave it empty; there the default access group is used, which is the
/// first entry of `keychain-access-groups`, i.e. the very same shared group.
enum KeychainConfig {
  static let service = "group.com.developerfromjokela.OpenCARWINGS"

  static var accessGroup: String? {
    guard let prefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String,
          !prefix.isEmpty else { return nil }
    let teamPrefix = prefix.hasSuffix(".") ? prefix : prefix + "."
    return teamPrefix + "com.developerfromjokela.OpenCARWINGS"
  }

  static func keychain() -> Keychain {
    guard let accessGroup else { return Keychain(service: service) }
    return Keychain(service: service, accessGroup: accessGroup)
  }
}

@propertyWrapper
struct KeychainStorage: DynamicProperty {
  let key: String
  @State private var value: String
  init(wrappedValue: String = "", _ key: String) {
    self.key = key
      let initialValue = (try? KeychainConfig.keychain().get(key)) ?? wrappedValue
    self._value = State<String>(initialValue: initialValue)
  }
  var wrappedValue: String {
    get  { value }
  
    nonmutating set {
      value = newValue
      do {
          try KeychainConfig.keychain().set(value, key: key)
      } catch let error {
        fatalError("\(error)")
      }
    }
  }
  var projectedValue: Binding<String> {
    Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }
}
