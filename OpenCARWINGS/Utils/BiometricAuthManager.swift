//
//  BiometricAuthManager.swift
//  OpenCARWINGS
//
//  Created by Oleksandr Palian on 30.8.2026.
//

import Foundation
import LocalAuthentication
import SwiftUI
import KeychainAccess

@MainActor
public final class BiometricAuthManager: ObservableObject {
    public static let shared = BiometricAuthManager()
    
    @AppStorage("isBiometricsEnabled") public var isBiometricsEnabled: Bool = false
    
    private let pinKeychainKey = "ocw_stored_command_pin"
    
    private init() {}
    
    /// Evaluates whether biometrics is available on the device
    public func canEvaluateBiometrics() -> (canEvaluate: Bool, biometryType: LABiometryType, error: Error?) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return (canEvaluate, context.biometryType, error)
    }
    
    /// User-friendly name of the available biometrics (Face ID, Touch ID, Optic ID, or Biometrics)
    public var biometryName: String {
        let (_, biometryType, _) = canEvaluateBiometrics()
        switch biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        @unknown default:
            return "Biometrics"
        }
    }
    
    /// Checks if a PIN is stored securely in Keychain for biometric usage
    public var hasStoredPin: Bool {
        guard let pin = getStoredPin(), !pin.isEmpty else {
            return false
        }
        return true
    }
    
    /// Stores the command PIN securely in Keychain for biometric authentication
    public func savePin(_ pin: String) {
        try? KeychainConfig.keychain().set(pin, key: pinKeychainKey)
    }
    
    /// Retrieves the stored command PIN from Keychain
    public func getStoredPin() -> String? {
        return try? KeychainConfig.keychain().get(pinKeychainKey)
    }
    
    /// Removes the stored command PIN from Keychain
    public func removeStoredPin() {
        try? KeychainConfig.keychain().remove(pinKeychainKey)
    }

    /// Checks whether `pin` is the PIN currently stored for biometric authentication
    public func isStoredPin(_ pin: String) -> Bool {
        guard let storedPin = getStoredPin(), !storedPin.isEmpty else {
            return false
        }
        return storedPin == pin
    }

    /// Turns biometric authentication off and discards the stored PIN
    public func disableBiometrics() {
        removeStoredPin()
        isBiometricsEnabled = false
    }
    
    /// Evaluates biometric authentication and returns the stored PIN if successful
    public func authenticateAndGetPin(reason: String? = nil) async -> (success: Bool, pin: String?, error: String?) {
        guard isBiometricsEnabled else {
            return (false, nil, "Biometrics disabled")
        }
        
        guard let storedPin = getStoredPin(), !storedPin.isEmpty else {
            return (false, nil, "No stored PIN found")
        }
        
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return (false, nil, error?.localizedDescription ?? "Biometrics unavailable")
        }
        
        let localizedReason = reason ?? "Authorize remote command with \(biometryName)"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason)
            if success {
                return (true, storedPin, nil)
            } else {
                return (false, nil, "Authentication failed")
            }
        } catch let evalError {
            return (false, nil, evalError.localizedDescription)
        }
    }
}
