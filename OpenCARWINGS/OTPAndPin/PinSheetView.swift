//
//  PinSheetView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import SwiftUI

struct PinSheetView: View {
    var errorMessage: String? = nil
    var onSubmit: (_ otp: String) -> Void

    @State private var otp: String = ""
    @State private var saveForBiometrics: Bool = true
    private let otpLength = 4
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject private var bioManager = BiometricAuthManager.shared

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            VStack(alignment: .center, spacing: 6) {
                Text("Command PIN")
                    .font(.title3.weight(.semibold))
                Text("Enter your 4-digit security PIN for sensitive commands")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            DigitCodeField(length: otpLength, code: $otp) {
                handleSubmission(pin: otp)
            }

            if bioManager.canEvaluateBiometrics().canEvaluate {
                Toggle(isOn: $saveForBiometrics) {
                    HStack(spacing: 6) {
                        Image(systemName: bioManager.biometryName == "Face ID" ? "faceid" : "touchid")
                            .foregroundStyle(.blue)
                        Text("Save PIN for \(bioManager.biometryName)")
                            .font(.footnote)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }

            if bioManager.isBiometricsEnabled && bioManager.hasStoredPin {
                Button {
                    Task {
                        let (success, pin, _) = await bioManager.authenticateAndGetPin()
                        if success, let pin {
                            presentationMode.wrappedValue.dismiss()
                            onSubmit(pin)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: bioManager.biometryName == "Face ID" ? "faceid" : "touchid")
                        Text("Use \(bioManager.biometryName)")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                    .padding(.vertical, 6)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

        }
        .padding(.horizontal)
        .scrollContentBackground(.hidden)
        .presentationDetents([.medium, .large, .height(340)])
        .onDisappear {
            otp = ""
        }
        .onAppear {
            otp = ""
            saveForBiometrics = bioManager.isBiometricsEnabled
        }
    }
    
    private func handleSubmission(pin: String) {
        if bioManager.canEvaluateBiometrics().canEvaluate {
            if saveForBiometrics {
                // Also re-arms biometrics after a PIN change made the previous one stale
                bioManager.savePin(pin)
                bioManager.isBiometricsEnabled = true
            } else {
                bioManager.disableBiometrics()
            }
        }
        presentationMode.wrappedValue.dismiss()
        onSubmit(pin)
    }
}
