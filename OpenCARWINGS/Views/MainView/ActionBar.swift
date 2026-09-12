//
//  ActionBar.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import RestAPI

struct ActionBar: View {
    @State private var showChargePopup = false
    @State private var showChargeOptsPopup = false
    @State private var showLockPopup = false
    @State private var showUnlockPopup = false
    @State private var showHornUnlock = false
    @State private var showCablePopup = false
    @State private var showACPopup = false
    @State private var showACTempPopup = false
    @State private var isFanSpin = false
    @State private var rotationAngle = 0.0
    @State private var acTemp: Int = 21

    var sendCommand: (Int, Bool, [String: AnyJSON]?) async -> Void
    @Binding var car: Car?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Preferred size
            buttonRow(buttonSize: 50, spacing: 10)

            // Slightly smaller
            buttonRow(buttonSize: 46, spacing: 8)

            // Smaller still
            buttonRow(buttonSize: 42, spacing: 6)

            // Compact fallback
            buttonRow(buttonSize: 38, spacing: 5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
        .onChange(of: car?.evInfo.isAcStatus) { _, newValue in
            if newValue != true {
                isFanSpin = false
            }
        }
    }

    // MARK: - Button Row

    @ViewBuilder
    private func buttonRow(buttonSize: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            // Unlock
            if car?.supportedCommands?.contains(7) == true {
                actionButton(
                    systemName: "lock.open.fill",
                    isLoading: car?.isCommandRequested == true && car?.commandType == 7,
                    background: .gray,
                    size: buttonSize
                ) {
                    showUnlockPopup = true
                }
                .disabled(car?.isCommandRequested == true)
                .alert(isPresented: $showUnlockPopup) {
                    Alert(
                        title: Text("Unlock Car"),
                        message: Text("Are you sure?"),
                        primaryButton: .default(Text("Continue")) {
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(7, false, nil)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            // Lock
            if car?.supportedCommands?.contains(8) == true {
                actionButton(
                    systemName: "lock.fill",
                    isLoading: car?.isCommandRequested == true && car?.commandType == 8,
                    background: .gray,
                    size: buttonSize
                ) {
                    showLockPopup = true
                }
                .disabled(car?.isCommandRequested == true)
                .alert(isPresented: $showLockPopup) {
                    Alert(
                        title: Text("Lock Car"),
                        message: Text("Are you sure?"),
                        primaryButton: .default(Text("Continue")) {
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(8, false, nil)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            // Charge
            actionButton(
                systemName: "bolt.fill",
                isLoading: car?.isCommandRequested == true && (car?.commandType == 2 || car?.commandType == 6),
                background: (car?.evInfo.isCharging == true || car?.evInfo.isQuickCharging == true) ? Color.accentColor : .gray,
                size: buttonSize
            ) {
                if car?.supportedCommands?.contains(6) == true {
                    showChargeOptsPopup = true
                } else {
                    showChargePopup = true
                }
            }
            .disabled(car?.isCommandRequested == true || car?.evInfo.isCharging == true)
            .alert(isPresented: $showChargePopup) {
                Alert(
                    title: Text("Start charging"),
                    message: Text("Are you sure?"),
                    primaryButton: .default(Text("Continue")) {
                        Task {
                            car?.isCommandRequested = true
                            await sendCommand(2, false, nil)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .confirmationDialog(Text("Start charging"), isPresented: $showChargeOptsPopup) {
                Button(LocalizedStringKey("Charging to 100%")) {
                    Task {
                        car?.isCommandRequested = true
                        await sendCommand(2, false, nil)
                    }
                }
                Button(LocalizedStringKey("Charging to 80%")) {
                    Task {
                        car?.isCommandRequested = true
                        await sendCommand(6, false, nil)
                    }
                }
                Button(LocalizedStringKey("Cancel"), role: .cancel) {}
            } message: {
                Text("Start charging")
            }

            // Plug / Cable status
            actionButton(
                systemName: "powerplug.fill",
                isLoading: false,
                background: car?.evInfo.isPluggedIn == true ? Color.accentColor : .gray,
                size: buttonSize
            ) {
                showCablePopup = true
            }
            .alert(isPresented: $showCablePopup) {
                Alert(
                    title: Text("Charging cable"),
                    message: car?.evInfo.isPluggedIn == true
                        ? Text("AC charging cable is plugged in")
                        : Text("AC charging cable is unplugged")
                )
            }

            // Fan / A/C
            actionButton(
                systemName: "fanblades.fill",
                isLoading: car?.isCommandRequested == true && (car?.commandType == 3 || car?.commandType == 4),
                background: car?.evInfo.isAcStatus == true ? Color.accentColor : .gray,
                size: buttonSize,
                rotation: car?.evInfo.isAcStatus == true ? rotationAngle : 0,
                startSpinning: car?.evInfo.isAcStatus == true
            ) {
                if car?.tcuType == .ficosa2016 && car?.evInfo.isAcStatus != true {
                    showACTempPopup = true
                } else {
                    showACPopup = true
                }
            }
            .disabled(car?.isCommandRequested == true)
            .alert(isPresented: $showACPopup) {
                Alert(
                    title: Text(car?.evInfo.isAcStatus == true ? "Stop A/C" : "Start A/C"),
                    message: Text("Are you sure?"),
                    primaryButton: .default(Text("Continue")) {
                        Task {
                            car?.isCommandRequested = true
                            await sendCommand(car?.evInfo.isAcStatus == true ? 4 : 3, false, nil)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .popover(isPresented: $showACTempPopup) {
                VStack {
                    if #available(iOS 26.0, *) {
                        Picker("Temperature", selection: $acTemp) {
                            ForEach(16...31, id: \.self) { number in
                                Text("\(number) °C").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .buttonSizing(.flexible)
                        .presentationCompactAdaptation(.popover)
                    } else {
                        Picker("Temperature", selection: $acTemp) {
                            ForEach(16...31, id: \.self) { number in
                                Text("\(number) °C").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .presentationCompactAdaptation(.popover)
                    }

                    if #available(iOS 26.0, *) {
                        Button(LocalizedStringKey("Start A/C")) {
                            showACPopup = false
                            showACTempPopup = false
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(3, false, [
                                    "unit": AnyJSON.number(0),
                                    "temp": AnyJSON.number(Double(acTemp))
                                ])
                            }
                        }
                        .buttonSizing(.flexible)
                        .buttonStyle(.glass)
                    } else {
                        Button(LocalizedStringKey("Start A/C")) {
                            showACPopup = false
                            showACTempPopup = false
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(3, false, [
                                    "unit": AnyJSON.number(0),
                                    "temp": AnyJSON.number(Double(acTemp))
                                ])
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }

            // Horn & Lights
            if car?.supportedCommands?.contains(11) == true {
                actionButton(
                    systemName: "horn.blast.fill",
                    isLoading: car?.isCommandRequested == true && car?.commandType == 11,
                    background: .gray,
                    size: buttonSize
                ) {
                    showHornUnlock = true
                }
                .disabled(car?.isCommandRequested == true)
                .alert(isPresented: $showHornUnlock) {
                    Alert(
                        title: Text("Horn & Lights"),
                        message: Text("Are you sure?"),
                        primaryButton: .default(Text("Continue")) {
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(11, false, nil)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    // MARK: - Reusable Button

    @ViewBuilder
    private func actionButton(
        systemName: String,
        isLoading: Bool,
        background: Color,
        size: CGFloat,
        rotation: Double = 0,
        startSpinning: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: systemName)
                        .font(.system(size: size * 0.48))
                        .rotationEffect(.degrees(rotation), anchor: .center)
                        .onAppear {
                            if startSpinning && !isFanSpin {
                                isFanSpin = true
                                withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                                    rotationAngle += 360
                                }
                            }
                        }
                }
            }
            .frame(width: size, height: size)
            .foregroundColor(.white)
        }
        .background(background)
        .cornerRadius(size / 2)
    }
}

#Preview {
    ActionBar(sendCommand: { _, _, _ in }, car: .constant(nil))
}
