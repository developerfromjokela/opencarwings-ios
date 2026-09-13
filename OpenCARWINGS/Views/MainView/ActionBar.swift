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
    @State private var acTemp: Int = 21

    var sendCommand: (Int, Bool, [String: AnyJSON]?) async -> Void
    @Binding var car: Car?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Preferred size
            buttonRow(buttonSize: 50, spacing: 10)

            buttonRow(buttonSize: 46, spacing: 8)

            buttonRow(buttonSize: 42, spacing: 6)

            buttonRow(buttonSize: 38, spacing: 5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
    }

    // MARK: - Button Row

    @ViewBuilder
    private func buttonRow(buttonSize: CGFloat, spacing: CGFloat) -> some View {
        let row = HStack(spacing: spacing) {
            // Unlock
            if car?.supportedCommands?.contains(7) == true {
                ScalableActionButton(
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
                ScalableActionButton(
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
            ScalableActionButton(
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
            ScalableActionButton(
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
            ScalableActionButton(
                systemName: "fanblades.fill",
                isLoading: car?.isCommandRequested == true && (car?.commandType == 3 || car?.commandType == 4),
                background: car?.evInfo.isAcStatus == true ? Color.accentColor : .gray,
                size: buttonSize,
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
                ScalableActionButton(
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
        
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                row
            }
        } else {
            row
        }
    }
}

// MARK: - Scalable action button

struct ScalableActionButton: View {
    var systemName: String
    var isLoading: Bool
    var background: Color
    var size: CGFloat
    var startSpinning: Bool = false
    var action: () -> Void

    @State private var rotationAngle: Double = 0
    @State private var animationToken = UUID()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        buttonContent
            .onAppear {
                updateAnimation()
            }
            .onChange(of: startSpinning) { _, _ in
                updateAnimation()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    restartAnimation()
                }
            }
    }

    @ViewBuilder
    private var buttonContent: some View {
        let baseBtn = Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: systemName)
                        .font(.system(size: size * 0.48))
                        .rotationEffect(.degrees(rotationAngle), anchor: .center)
                        .id(animationToken)
                }
            }
            .frame(width: size, height: size)
            .foregroundColor(.white)
        }
        
        if #available(iOS 26.0, *) {
            baseBtn.buttonStyle(.plain)
                .glassEffect(.regular.tint(background).interactive(), in: .ellipse)
                .buttonBorderShape(.circle)
        } else {
            baseBtn.clipShape(Circle())
                .buttonStyle(.plain)
                .background(background)
        }
    }

    private func updateAnimation() {
        if startSpinning {
            restartAnimation()
        } else {
            stopAnimation()
        }
    }

    private func restartAnimation() {
        rotationAngle = 0
        animationToken = UUID()
        
        guard startSpinning else { return }

        // Delay starting the loop until stop is rendered
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            rotationAngle = 0
        }
    }
}

#Preview {
    ActionBar(sendCommand: { _, _, _ in }, car: .constant(nil))
}
