//
//  OtpSheetView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import SwiftUI

struct OtpSheetView: View {
    var errorMessage: String? = nil
    var onSubmit: (_ otp: String) -> Void

    @State private var otp: String = ""
    private let otpLength = 6
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>


    var body: some View {
            VStack(alignment: .center, spacing: 12) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Enter 2FA code")
                          .font(.title3.weight(.semibold))
                    Text("Enter the 6-digit code from your authenticator app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                DigitCodeField(length: otpLength, code: $otp) {
                    // auto-submit once all 6 digits are entered
                    presentationMode.wrappedValue.dismiss()
                    onSubmit(otp)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

            }.scrollContentBackground(.hidden).presentationDetents([.medium, .large, .height(300)]).onDisappear {
            otp = ""
        }.onAppear {
            otp = ""
        }
    }
}
