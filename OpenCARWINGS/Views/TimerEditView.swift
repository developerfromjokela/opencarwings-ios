//
//  TimerEditView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 16.10.2025.
//

import SwiftUI
import Get
import RestAPI

struct TimerEditView: View {
    @Binding var token: String
    @Binding var refreshToken: String
    @Binding var serverUrl: String
    @Binding var car: Car?
    
    let timer: CommandTimerSetting?
    @State private var timerName: String = ""
    @State private var timerEnabled = true
    @State private var command: Int = 1
    @State private var timerType: Int = 0
    @State private var time: Date = Date.now
    @State private var date: Date = Date.now
    
    @State private var mon = false
    @State private var tue = false
    @State private var wed = false
    @State private var thu = false
    @State private var fri = false
    @State private var sat = false
    @State private var sun = false
    
    @State private var showError = false
    @State private var errorMsg: String = ""
    @State private var deleteConfirmation = false
    @State private var showProgress = false
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Form {
            Section {
                TextField(
                    "Timer name",
                     text: $timerName
                )
                Toggle(isOn: $timerEnabled) {
                    Text("Timer enabled")
                }
                
                DatePicker("Select time", selection: $time, displayedComponents: .hourAndMinute)
                
                Picker("Command", selection: $command) {
                        Text("Refresh data").tag(1)
                        Text("Charge start").tag(2)
                        Text("A/C on").tag(3)
                        Text("A/C off").tag(4)
                        Text("Read configuration").tag(5)
                    }
            }
            
            Section {
                Picker("Repetition", selection: $timerType) {
                    Text("One-time").tag(0)
                    Text("Repeating").tag(1)
                }.pickerStyle(.segmented)
                
                
                if timerType == 0 {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } else if timerType == 1 {
                    Toggle(isOn: $mon) {
                        Text(DateUtils.getFullWeekdays()[1])
                    }
                    Toggle(isOn: $tue) {
                        Text(DateUtils.getFullWeekdays()[2])
                    }
                    Toggle(isOn: $wed) {
                        Text(DateUtils.getFullWeekdays()[3])
                    }
                    Toggle(isOn: $thu) {
                        Text(DateUtils.getFullWeekdays()[4])
                    }
                    Toggle(isOn: $fri) {
                        Text(DateUtils.getFullWeekdays()[5])
                    }
                    Toggle(isOn: $sat) {
                        Text(DateUtils.getFullWeekdays()[6])
                    }
                    Toggle(isOn: $sun) {
                        Text(DateUtils.getFullWeekdays()[0])
                    }
                }
            }
            
        }.navigationTitle(Text(timer?.name ?? "Add new timer")).toolbar {
            HStack {
                if showProgress {
                    ProgressView().progressViewStyle(.circular)
                } else {
                    if timer != nil {
                        Button("Delete") {
                            deleteConfirmation = true
                        }
                    }
                    
                    Button("Save") {
                        if timerName.isEmpty {
                            errorMsg = NSLocalizedString("Please set a name for timer", comment: "")
                            showError = true
                            return
                        }
                        
                        if !mon && !tue && !wed && !thu && !fri && !sat && !sun && timerType == 1 {
                            errorMsg = NSLocalizedString("Please set at least one day of the week", comment: "")
                            showError = true
                            return
                        }
                        Task {
                            await addOrUpdateTimer()
                        }
                    }
                }
            }.confirmationDialog(NSLocalizedString("Delete this timer?", comment: ""),
                                 isPresented: $deleteConfirmation) {
                                   Button("Delete") {
                                       deleteConfirmation = false
                                       Task {
                                           await deleteTimer()
                                       }
                                  }
                                   Button("Cancel", role: .cancel) {
                                   }
                               } message: {
                                   Text("Delete this timer?")
                               }
        }.alert(errorMsg, isPresented: $showError) {}.onAppear {
            if let timer = timer {
                timerName = timer.name
                timerEnabled = timer.isEnabled == true
                command = timer.commandType ?? 1
                timerType = timer.timerType ?? 0
                date = DateUtils.correctDateBasedOnTimerTime(timer) ?? Date.now
                time = DateUtils.parseToLocalTimerTime(timer.time) ?? Date.now
                mon = timer.isWeekdayMon ?? false
                tue = timer.isWeekdayTue ?? false
                wed = timer.isWeekdayWed ?? false
                thu = timer.isWeekdayThu ?? false
                fri = timer.isWeekdayFri ?? false
                sat = timer.isWeekdaySat ?? false
                sun = timer.isWeekdaySun ?? false
            }
        }
    }
    
    func deleteTimer() async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, token)
        showProgress = true
        do {
            try await client.send(Paths.api.car.vin(car!.vin).timers.id(String(timer?.id ?? -1)).delete)
            self.presentationMode.wrappedValue.dismiss()
        } catch let e as OCWAPIError {
            showProgress = false
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, token)
            switch autCheckResult {
            case let .ok(newToken):
                token = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await deleteTimer()
                break
            case let .error(error):
                showError = true
                errorMsg = "Cannot connect to server. Please try again later.";
                if let apiErr = error as? OCWAPIError {
                    if apiErr.statusCode == 503 {
                        errorMsg = "Server is unavailable. Please try again later.";
                    } else {
                        errorMsg = apiErr.apiError?.detail ?? apiErr.apiError?.error ?? errorMsg
                    }
                }
                break
            case .invalidRefreshToken:
                refreshToken = ""
                break
            }
        } catch let e {
            print(e)
            showProgress = false
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
    
    func addOrUpdateTimer() async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, token)
        showProgress = true
        do {
            var newTimer = CommandTimerSetting(name: timerName, time: DateUtils.formatToUTCTimerTime(time) ?? "")
            newTimer.timerType = timerType
            newTimer.commandType = command
            if timerType == 0 {
                newTimer.date = .init((DateUtils.correctDateSelectionToUTC(date, time) ?? Date.now).ISO8601Format().split(separator: "T").first?.lowercased() ?? "")
            } else if timerType == 1 {
                newTimer.isWeekdayMon = mon
                newTimer.isWeekdayTue = tue
                newTimer.isWeekdayWed = wed
                newTimer.isWeekdayThu = thu
                newTimer.isWeekdayFri = fri
                newTimer.isWeekdaySat = sat
                newTimer.isWeekdaySun = sun
            }
            newTimer.isEnabled = timerEnabled
            if timer == nil {
                try await client.send(Paths.api.car.vin(car!.vin).timers.post(newTimer))
            } else {
                print(newTimer)
                newTimer.id = timer!.id
                try await client.send(Paths.api.car.vin(car!.vin).timers.id(String(timer!.id ?? -1)).patch(newTimer))
            }
            self.presentationMode.wrappedValue.dismiss()
        } catch let e as OCWAPIError {
            showProgress = false
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, token)
            switch autCheckResult {
            case let .ok(newToken):
                token = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await deleteTimer()
                break
            case let .error(error):
                showError = true
                errorMsg = "Cannot connect to server. Please try again later.";
                if let apiErr = error as? OCWAPIError {
                    if apiErr.statusCode == 503 {
                        errorMsg = "Server is unavailable. Please try again later.";
                    } else {
                        errorMsg = apiErr.apiError?.detail ?? apiErr.apiError?.error ?? errorMsg
                    }
                }
                break
            case .invalidRefreshToken:
                refreshToken = ""
                break
            }
        } catch let e {
            print(e)
            showProgress = false
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
}

