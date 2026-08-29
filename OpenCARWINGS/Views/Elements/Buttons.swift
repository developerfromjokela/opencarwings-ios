//
//  Buttons.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI

struct LargeButtonStyle: ButtonStyle {
    
    let backgroundColor: Color
    let foregroundColor: Color
    let isDisabled: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        let currentForegroundColor = isDisabled || configuration.isPressed ? foregroundColor.opacity(0.3) : foregroundColor
        return configuration.label
            .padding(10)
            .foregroundColor(currentForegroundColor)
            .background(isDisabled || configuration.isPressed ? backgroundColor.opacity(0.3) : backgroundColor)
            .cornerRadius(21)
            .font(Font.system(size: 19, weight: .semibold))
    }
}

struct LargeButton: View {
    
    private static let buttonHorizontalMargins: CGFloat = 5
    
    var backgroundColor: Color
    var foregroundColor: Color
    
    private let title: String
    private let action: () async -> Void
    
    @Binding var disabled: Bool
    
    init(title: String,
         disabled: Binding<Bool>,
         backgroundColor: Color = Color.green,
         foregroundColor: Color = Color.white,
         action: @escaping () async -> Void) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.title = title
        self.action = action
        self._disabled = disabled
    }
    
    var body: some View {
        HStack {
            Spacer(minLength: LargeButton.buttonHorizontalMargins)
            Button(action: {
                Task {
                    await self.action()
                }
            }) {
                Text(self.title)
                    .frame(maxWidth:.infinity)
            }
            .buttonStyle(LargeButtonStyle(backgroundColor: backgroundColor,
                                          foregroundColor: foregroundColor,
                                          isDisabled: disabled))
                .disabled(self.disabled)
            Spacer(minLength: LargeButton.buttonHorizontalMargins)
        }
        .frame(maxWidth:.infinity)
    }
}

