//
//  SetPinSheetView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import SwiftUI
import Get
import RestAPI

struct SetPinSheetView: View {
    var otpRequired: Bool
    var errorMessage: String? = nil
    var onSubmit: (_ pin: String) -> Void

    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var otp: String = ""
    @State private var localError: String?
    @State private var loading = false
    
    @Binding var serverUrl: String
    @Binding var accessToken: String
    @Binding var refreshToken: String

    private let pinLength = 4
    private let otpLength = 6
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>


    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 8) {
                Text("Set command PIN")
                    .font(.title3.weight(.semibold))
                Text("Choose a 4-digit PIN used to confirm remote commands")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PIN").font(.subheadline.weight(.medium))
                DigitCodeField(length: pinLength, code: $pin, isSecure: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm PIN").font(.subheadline.weight(.medium))
                DigitCodeField(length: pinLength, code: $confirmPin, isSecure: true)
            }

            if let message = localError ?? errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if otpRequired {
                VStack(alignment: .leading, spacing: 8) {
                    Text("2FA code").font(.subheadline.weight(.medium))
                    DigitCodeField(length: otpLength, code: $otp)
                }
            }

            Button("Submit") { Task {await submit()} }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!isValid)
        }.presentationDetents([.medium, .large]).onDisappear {
            otp = ""
            pin = ""
        }.onAppear {
            otp = ""
            pin = ""
        }
    }

    private var isValid: Bool {
        pin.count == pinLength &&
        confirmPin.count == pinLength &&
        (!otpRequired || otp.count == otpLength) && !loading
    }

    private func submit() async {
        guard pin.count == pinLength, confirmPin.count == pinLength else { return }
        guard pin == confirmPin else {
            localError = "PINs don't match"
            confirmPin = ""
            return
        }
        if otpRequired { guard otp.count == otpLength else { return } }
        loading = true

        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        do {
            try await client.send(Paths.account.pin.post(.init(otpCode: otp, newPin: pin, newPinConfirm: confirmPin)))
            if BiometricAuthManager.shared.canEvaluateBiometrics().canEvaluate {
                BiometricAuthManager.shared.savePin(pin)
                BiometricAuthManager.shared.isBiometricsEnabled = true
            }
            presentationMode.wrappedValue.dismiss()
            onSubmit(pin)
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await submit()
                break
            case let .error(error):
                loading = false
                localError = "Cannot connect to server. Please try again later.";
                if let apiErr = error as? OCWAPIError {
                    if apiErr.statusCode == 503 {
                        localError = "Server is unavailable. Please try again later.";
                    } else {
                        localError = apiErr.apiError?.detail ?? apiErr.apiError?.error
                    }
                }
                break
            default:
                break
            }
        } catch _ {
            loading = false
            localError = "Cannot connect to server. Please try again later.";
        }
    }
}
