//
//  KeyChainWrapper.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation
import SwiftUI
import KeychainAccess


@propertyWrapper
struct KeychainStorage: DynamicProperty {
  let key: String
  @State private var value: String
  init(wrappedValue: String = "", _ key: String) {
    self.key = key
      let initialValue = (try? Keychain(service: "group.com.developerfromjokela.OpenCARWINGS", accessGroup: "R7R98T4924.com.developerfromjokela.OpenCARWINGS").get(key)) ?? wrappedValue
    self._value = State<String>(initialValue: initialValue)
  }
  var wrappedValue: String {
    get  { value }
  
    nonmutating set {
      value = newValue
      do {
          try Keychain(service: "group.com.developerfromjokela.OpenCARWINGS", accessGroup: "R7R98T4924.com.developerfromjokela.OpenCARWINGS").set(value, key: key)
      } catch let error {
        fatalError("\(error)")
      }
    }
  }
  var projectedValue: Binding<String> {
    Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }
}
