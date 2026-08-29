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

    
    var sendCommand: (Int, Bool, [String:AnyJSON]?) async -> Void
    
    @Binding var car: Car?
    var body: some View {
        HStack(spacing: 10) {
            if (car?.supportedCommands?.contains(7) == true) {
                Button(action: {
                    showUnlockPopup = true
                }) {
                    if car?.isCommandRequested == true && car?.commandType == 7 {
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                }.background(Color.gray).cornerRadius(25).disabled(car?.isCommandRequested == true).alert(isPresented: $showUnlockPopup) {
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
            if (car?.supportedCommands?.contains(8) == true) {
                Button(action: {
                    showLockPopup = true
                }) {
                    if car?.isCommandRequested == true && car?.commandType == 8 {
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                }.background(Color.gray).cornerRadius(25).disabled(car?.isCommandRequested == true).alert(isPresented: $showLockPopup) {
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
            Button(action: {
                if (car?.supportedCommands?.contains(6) == true) {
                    showChargeOptsPopup = true
                    return
                }
                showChargePopup = true
            }) {
                if car?.isCommandRequested == true && (car?.commandType == 2 || car?.commandType == 6) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 50, height: 50)
                } else {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
            }.background((car?.evInfo.isCharging == true || car?.evInfo.isQuickCharging == true) ? Color.accentColor : Color.gray).cornerRadius(25).disabled((car?.isCommandRequested == true || car?.evInfo.isCharging == true)).alert(isPresented: $showChargePopup) {
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
            }.confirmationDialog(Text("Start charging"), isPresented: $showChargeOptsPopup) {
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
            Button(action: {
                showCablePopup = true
            }) {
                Image(systemName: "powerplug.fill")
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }.background(car?.evInfo.isPluggedIn == true ? Color.accentColor : Color.gray).cornerRadius(25).alert(isPresented: $showCablePopup) {
                Alert(
                    title: Text("Charging cable"),
                    message: car?.evInfo.isPluggedIn == true ? Text("AC charging cable is plugged in") : Text("AC charging cable is unplugged")
                )
            }
            Button(action: {
                if (car?.tcuType == .ficosa2016 && car?.evInfo.isAcStatus != true) {
                    showACTempPopup = true
                } else {
                    showACPopup = true
                }
            }) {
                if car?.isCommandRequested == true && (car?.commandType == 3 || car?.commandType == 4) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 50, height: 50)
                } else {
                    if car?.evInfo.isAcStatus == true {
                        Image(systemName: "fanblades.fill")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotationAngle), anchor: .center) // <- NEW
                            .onAppear {
                                if (!isFanSpin) {
                                    isFanSpin = true
                                    withAnimation(Animation.linear(duration: 0.7).repeatForever(autoreverses: false)) {
                                        rotationAngle += 360
                                    }
                                }
                            }
                    } else {
                        Image(systemName: "fanblades.fill")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                }
            }.background(car?.evInfo.isAcStatus == true ? Color.accentColor : Color.gray).cornerRadius(25).disabled(car?.isCommandRequested == true).alert(isPresented: $showACPopup) {
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
            }.popover(isPresented: $showACTempPopup) {
                VStack() {
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
                                await sendCommand(3, false, ["unit": AnyJSON.number(0), "temp": AnyJSON.number(Double($acTemp.wrappedValue))])
                            }
                        }.buttonSizing(.flexible).buttonStyle(.glass)
                    } else {
                        Button(LocalizedStringKey("Start A/C")) {
                            showACPopup = false
                            showACTempPopup = false
                            Task {
                                car?.isCommandRequested = true
                                await sendCommand(3, false, ["unit": AnyJSON.number(0), "temp": AnyJSON.number(Double($acTemp.wrappedValue))])
                            }
                        }.buttonStyle(.bordered)
                    }
                }.padding()
            }.onChange(of: car?.evInfo.isAcStatus) {_, _ in
                if car?.evInfo.isAcStatus != true {
                    isFanSpin = false
                }
            }
            if (car?.supportedCommands?.contains(11) == true) {
                Button(action: {
                    showHornUnlock = true
                }) {
                    if car?.isCommandRequested == true && car?.commandType == 11 {
                        ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 50, height: 50)
                    } else {
                        Image(systemName: "horn.blast.fill")
                            .font(.system(size: 24))
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                }.background(Color.gray).cornerRadius(25).disabled(car?.isCommandRequested == true).alert(isPresented: $showHornUnlock) {
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
        .foregroundColor(.primary)
        .padding(.vertical)
    }
}

#Preview {
    ActionBar(sendCommand: {_,_,_ in }, car: .constant(nil))
}
