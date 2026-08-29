//
//  SetPinSheetView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import SwiftUI

struct PinSheetView: View {
    var errorMessage: String? = nil
    var onSubmit: (_ otp: String) -> Void

    @State private var otp: String = ""
    private let otpLength = 4
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>


    var body: some View {
            VStack(alignment: .center, spacing: 12) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Command PIN")
                          .font(.title3.weight(.semibold))
                    Text("Enter your 4-digit security PIN for sensitive commands")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                DigitCodeField(length: otpLength, code: $otp) {
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
