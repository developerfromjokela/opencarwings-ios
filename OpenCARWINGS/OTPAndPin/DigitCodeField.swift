//
//  DigitCodeField.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import SwiftUI

struct DigitCodeField: View {
    let length: Int
    @Binding var code: String
    var isSecure: Bool = false
    var onComplete: (() -> Void)? = nil

    @FocusState private var focusedIndex: Int?
    
    @State private var submitted = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<length, id: \.self) { index in
                DigitBox(text: bindingForDigit(at: index), isSecure: isSecure)
                    .focused($focusedIndex, equals: index)
                    .onChange(of: bindingForDigit(at: index).wrappedValue) { newValue in
                        handleChange(at: index, newValue: newValue)
                    }
            }
        }
        .onAppear { focusedIndex = 0; submitted = false }
    }

    private func bindingForDigit(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard index < code.count else { return "" }
                let i = code.index(code.startIndex, offsetBy: index)
                return String(code[i])
            },
            set: { setDigit($0, at: index) }
        )
    }

    private func setDigit(_ newValue: String, at index: Int) {
        var chars = Array(code)
        while chars.count < length { chars.append(" ") }

        let filtered = newValue.filter(\.isNumber)

        if filtered.count > 1 {
            distributePasted(filtered, startingAt: index)
            return
        }
        chars[index] = filtered.first ?? " "
        code = String(chars).trimmingTrailingSpaces()

        if code.count == length && !submitted {
            submitted = true
            onComplete?()
        }
    }

    private func distributePasted(_ digits: String, startingAt index: Int) {
        var chars = Array(code)
        while chars.count < length { chars.append(" ") }

        var i = index
        for ch in digits {
            guard i < length else { break }
            chars[i] = ch
            i += 1
        }
        code = String(chars).trimmingTrailingSpaces()
        focusedIndex = min(i, length - 1)

        if code.count == length && !submitted {
            submitted = true
            onComplete?()
        }
    }

    private func handleChange(at index: Int, newValue: String) {
        if !newValue.isEmpty && index < length - 1 {
            focusedIndex = index + 1
        }
    }
}

private struct DigitBox: View {
    @Binding var text: String
    var isSecure: Bool

    var body: some View {
        Group {
            if isSecure && !text.isEmpty {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .font(.title2.weight(.semibold))
        .frame(width: 44, height: 52)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 1))
    }
}

private extension String {
    func trimmingTrailingSpaces() -> String {
        var s = self
        while s.hasSuffix(" ") { s.removeLast() }
        return s
    }
}
