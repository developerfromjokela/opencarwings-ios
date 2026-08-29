//
//  TimersView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 16.10.2025.
//

import SwiftUI
import RestAPI

struct TimersView: View {
    @Binding var token: String
    @Binding var refreshToken: String
    @Binding var serverUrl: String
    @Binding var car: Car?
    var body: some View {
        List {
            if (car?.timerCommands ?? []).isEmpty {
                Text("No timers added")
            }
            ForEach(car?.timerCommands ?? [], id: \.id) {timer in
                NavigationLink(destination: TimerEditView(token: $token, refreshToken: $refreshToken, serverUrl: $serverUrl, car: $car, timer: timer)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: timer.isEnabled == true ? "checkmark.square" : "square")
                            Text(timer.name).font(.title3)
                        }
                        if timer.timerType == 0 {
                            Text("\(timer.commandTypeDisplay ?? "--") | \(DateUtils.formatToLocalDate(DateUtils.correctDateBasedOnTimerTime(timer), .none) ?? "--") | \(DateUtils.parseAndFormatToLocalTimerTime(timer.time) ?? "--")").font(.subheadline)
                        } else if timer.timerType == 1 {
                            Text("\(timer.commandTypeDisplay ?? "--") | \(DateUtils.formatCommandTimerDays(timer))\(DateUtils.parseAndFormatToLocalTimerTime(timer.time) ?? "--")").font(.subheadline)
                        }
                        Text("Last run: \(DateUtils.formatToLocalDate(timer.lastCommandExecution) ?? "--"), result: \(timer.lastCommandResult != -1 ? (timer.lastCommandResultDisplay ?? "--") : "--")").font(.caption)
                    }
                }
            }
        }.navigationTitle(Text("Timers")).toolbar {
            NavigationLink(destination: TimerEditView(token: $token, refreshToken: $refreshToken, serverUrl: $serverUrl, car: $car, timer: nil)) {
                Image(systemName: "plus")
            }
        }
    }
}
