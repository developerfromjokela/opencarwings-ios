//
//  MainView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import NotificationBannerSwift
import Get
import RestAPI
import MapKit
import CoreLocation
import WidgetKit

enum Kind: String {
    case navigationView
    case root
    case sheet
}


struct MainView: View {
    
    @Binding var refreshToken: String
    @KeychainStorage("ocw_username") private var username: String = ""
    @KeychainStorage("ocw_access_token") private var accessToken: String = ""
    @KeychainStorage("ocw_server") private var serverUrl: String = "https://opencarwings.viaaq.eu"
    
    @KeychainStorage("last_active_car") private var lastActiveCar: String = ""
    @KeychainStorage("cars_list") private var carsList: String = ""
    
    @State private var pages: [HomeItemData] = []
    
    @State private var showError = false
    @State private var errorMsg: String = ""
    
    @State private var cars: [RestAPI.CarSerializerList] = []
    
    @State private var alerts: [AlertHistoryFull] = []
    
    @State private var selectedCar: RestAPI.Car? = nil
    
    @State private var accountInfo: RestAPI.AccountDetail? = nil

    @State private var initialLoading = true
    
    @State private var isAnimatingFan = true
    
    @State private var notInitialWSConnect = false
    @State private var showSettings = false
    @State private var signOutProgress = false
    
    @State private var geocodedLoc: String? = ""
    @State private var timerText: String? = nil
    
    @State private var kind: Kind = .root
    
    @State private var ctxOutside = false
    
    @State private var showPinPrompt = false
    @State private var showSetupPinPrompt = false
    
    @State private var pendingCmdType = 0
    @State private var pendingCmdOutside = false
    @State private var pendingCmdArgs: [String:AnyJSON]? = nil
    @State private var pinErrorMsg: String? = nil
    
    
    var body: some View {
        if initialLoading {
            VStack(alignment: .center) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2.0).frame(alignment: .center)
            }.frame(minWidth: 0,  maxWidth: .infinity, minHeight: 0, maxHeight: .infinity).onAppear(perform: {
                Task {
                    connectWebServer()
                    await loadInitialData()
                }
            }).alert(isPresented: $showError) {
                Alert(
                    title: Text("Could not load"),
                    message: Text(LocalizedStringKey(errorMsg)),
                    primaryButton: .default(Text("Retry")) {
                        Task {
                            await loadInitialData()
                        }
                    },
                    secondaryButton: .default(Text("Sign out")) {
                        Task {
                            showError = false
                            signOutProgress = true
                            Task {
                                await makeSignOutReq()
                            }
                        }
                    },
                )
            }
        } else {
            NavigationView {
                ScrollView {
                    // Header with battery and status
                    PageHeader(selectedCar: $selectedCar)

                    CarRendering(car: $selectedCar)
                    
                    RangeDisplay(selectedCar: $selectedCar)
                    
                    LeafSegmentDisplay(activeSegments: selectedCar?.evInfo.chargeBars ?? 0, isCharging: selectedCar?.evInfo.isCharging == true, isQuickCharging: selectedCar?.evInfo.isQuickCharging == true)
                        .padding(.horizontal, 23).frame(alignment: .center)
                    
                    if (selectedCar?.tcuType == .ficosa2016 && selectedCar?.tcuVer == "TCU033") {
                        Text(String(format: NSLocalizedString("Cabin Temp: %@", comment: "Homepage Cabin Temp"), formatTemp(Measurement(value: selectedCar?.evInfo.cabinTemp ?? 0.0, unit: .celsius))))
                    }

                    ActionBar(sendCommand: sendTCUCommand, car: $selectedCar)

                    // Control sections
                    PagesList(pages: $pages, outside: $ctxOutside)

                    Spacer().padding(.bottom, 20)
                    
                    CarInfoBlock(car: $selectedCar).padding().padding(.horizontal, 11)
                }.refreshable {
                    await sendTCUCommand(1)
                }.toolbar(id: "main") {
                    ToolbarItem(id: "car", placement: .topBarLeading) {
                            Menu {
                                ForEach(cars, id: \.vin) { option in
                                    Button {
                                        lastActiveCar = option.vin
                                        Task {
                                            await updateCarInfo()
                                        }
                                    } label: {
                                        Text(option.nickname ?? option.vin)
                                            .font(.system(size: 74, weight: .bold)).foregroundColor(.primary) // Large font for dropdown
                                    }
                                }
                            } label: {
                                Text(selectedCar?.nickname ?? selectedCar?.vin ?? "") // Only show the selected option's name
                                    .font(.system(size: (selectedCar?.nickname ?? selectedCar?.vin ?? "").count > 16 ? 60 : 74, weight: .bold))
                                    .foregroundColor(.primary)
                                    .minimumScaleFactor(0.4) // Allow scaling if needed
                                    .padding(.vertical, 4) // Adjust for vertical fit
                            }

                        }
                        if #available(iOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                    ToolbarItem(id: "settings", placement: .topBarTrailing) {
                            Button(action: {
                                showSettings.toggle()
                            }) {
                                Image(systemName: "gear")
                            }
                        }
                }.sheet(isPresented: $showSettings) {
                    if #available(iOS 26.0, *) {
                        NavigationStack {
                            List {
                                VStack(alignment: .leading) {
                                    Text("Username")
                                    Text(username)
                                }
                                VStack(alignment: .leading) {
                                    Text("Cars under your account")
                                    Text(String(cars.count))
                                }
                                VStack(alignment: .leading) {
                                    Text("App Version")
                                    Text("\(Bundle.main.releaseVersionNumber ?? "??") (\(Bundle.main.buildVersionNumber ?? "0"))")
                                }
                                Button(action: {
                                    showSettings.toggle()
                                    signOutProgress = true
                                    Task {
                                        await makeSignOutReq()
                                    }
                                }) {
                                    Text("Sign out")
                                }
                            }.navigationTitle(Text("Settings")).scrollContentBackground(.hidden)
                        }.presentationDetents([.medium, .large])
                    } else {
                        NavigationView {
                            List {
                                VStack(alignment: .leading) {
                                    Text("Username")
                                    Text(username)
                                }
                                VStack(alignment: .leading) {
                                    Text("Cars under your account")
                                    Text(String(cars.count))
                                }
                                VStack(alignment: .leading) {
                                    Text("App Version")
                                    Text("\(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))")
                                }
                                Button(action: {
                                    showSettings.toggle()
                                    signOutProgress = true
                                    Task {
                                        await makeSignOutReq()
                                    }
                                }) {
                                    Text("Sign out")
                                }
                            }.navigationTitle(Text("Settings"))
                        }
                    }
                }
            }
            .sheet(isPresented: $showPinPrompt) {
                PinSheetView(errorMessage: pinErrorMsg, onSubmit: {pin in
                    if (pendingCmdType > 0) {
                        Task {
                            selectedCar?.isCommandRequested = true
                            await sendTCUCommandImpl(pendingCmdType, outside: pendingCmdOutside, args: pendingCmdArgs, commandPin: pin)
                            pendingCmdType = 0
                            pendingCmdOutside = false
                            pendingCmdArgs = nil
                        }
                    }
                })
            }
            .sheet(isPresented: $showSetupPinPrompt) {
                SetPinSheetView(otpRequired: accountInfo?.isIs2faEnabled == true, onSubmit: {pin in
                    if (pendingCmdType > 0) {
                        Task {
                            selectedCar?.isCommandRequested = true
                            await sendTCUCommandImpl(pendingCmdType, outside: pendingCmdOutside, args: pendingCmdArgs, commandPin: pin, refreshAccountInfo: true)
                            pendingCmdType = 0
                            pendingCmdOutside = false
                            pendingCmdArgs = nil
                        }
                    }
                }, serverUrl: $serverUrl, accessToken: $accessToken, refreshToken: $refreshToken)
            }
            .onAppear(perform: constructPages).loadingDialog(isPresented: $signOutProgress, message: "Signing in...").alert(errorMsg, isPresented: $showError) {}
        }
    }
    
    private func makeSignOutReq() async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        do {
            try await client.send(Paths.api.token.signout.post(TokenBlacklist(refresh: refreshToken)))
            
            logoutViewState()
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await makeSignOutReq()
                break
            default:
                logoutViewState()
                break
            }
        } catch _ {
            logoutViewState()
        }
    }
    
    private func connectWebServer() {
        var url: String = URL(string: serverUrl)!.appendingPathComponent("/ws/notif/").absoluteString
        url.replace(/^http/, with: "ws")
        WSClient.shared.configure(url: url, token: accessToken, onWSEvent: onWebSocketReceive)
        WSClient.shared.connect()
    }
    
    private func onWebSocketReceive(wsEvent: WSClientEvent) {
        switch wsEvent {
        case let .connected(silent):
            Task {
                await updateCarInfo()
            }
            if !notInitialWSConnect || silent {
                notInitialWSConnect = true
                return
            }
            let banner = GrowingNotificationBanner(title: "Connected!", style: .success)
            banner.show(queuePosition: .front, bannerPosition: .top)
            break
        case .disconnected:
            break
        case .reconnecting:
            let banner = GrowingNotificationBanner(title: "Connection lost, reconnecting...", style: .warning)
            banner.show(queuePosition: .front, bannerPosition: .top)
            break
        case let .clientError(err):
            print(err)
            if WSClient.shared.reconnectState() { return }
            let banner = GrowingNotificationBanner(title: "Could not establish connection to real-time update server", style: .danger)
            banner.show(queuePosition: .front, bannerPosition: .top)
            break
        case let .alert(alert):
            alerts.insert(alert, at: 0)
            let banner = GrowingNotificationBanner(title: "\(alert.car?.nickname ?? alert.car?.vin ?? "Notification"): \(alert.typeDisplay)", subtitle: alert.additionalData, style: .info)
            banner.show(queuePosition: .front, bannerPosition: .top)
            break
        case .serverAck:
            break
        case let .updatedCarInfo(car):
            if car.vin == lastActiveCar {
                let enabledTimers = car.timerCommands.filter {$0.isEnabled == true};
                if ctxOutside {
                    selectedCar = car
                    timerText = enabledTimers.count > 0 ? String(format: NSLocalizedString("%d timer(s) active", comment: "Shown under timers tab"), enabledTimers.count) : nil
                    let lat = Double(car.location.lat ?? "0.0") ?? 0.0
                    let lon = Double(car.location.lon ?? "0.0") ?? 0.0
                    geocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon), isHome: selectedCar?.location.isHome == true)
                } else {
                    withAnimation {
                        selectedCar = car
                        timerText = enabledTimers.count > 0 ? String(format: NSLocalizedString("%d timer(s) active", comment: "Shown under timers tab"), enabledTimers.count) : nil
                        let lat = Double(car.location.lat ?? "0.0") ?? 0.0
                        let lon = Double(car.location.lon ?? "0.0") ?? 0.0
                        geocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon), isHome: selectedCar?.location.isHome == true)
                    }
                }

            }
            break
        }
    }
    
    private func logoutViewState() {
        WSClient.shared.disconnect()
        initialLoading = true
        signOutProgress = false
        cars = []
        carsList = ""
        lastActiveCar = ""
        accessToken = ""
        refreshToken = ""
        pages = []
        showError = false
        errorMsg = ""
        alerts = []
        selectedCar = nil
        accountInfo = nil
        isAnimatingFan = true
        notInitialWSConnect = false
        showSettings = false
        geocodedLoc = ""
        timerText = nil
        kind = .root
        ctxOutside = false
        showPinPrompt = false
        showSetupPinPrompt = false
        pendingCmdArgs = nil
        pendingCmdType = 0
        pendingCmdOutside = false
        pinErrorMsg = nil
        // The stored PIN belongs to the account that just signed out
        BiometricAuthManager.shared.removeStoredPin()
    }
    
    private func updateCarInfo() async {
        if (lastActiveCar.isEmpty) {return}
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        do {
            let carResp: Response<Car> = try await client.send(Paths.api.car.vin(lastActiveCar).get)
            
            let alertResp: Response<[AlertHistoryFull]> = try await client.send(Paths.api.alerts.vin(lastActiveCar).get)
            
            alerts = alertResp.value
            let enabledTimers = carResp.value.timerCommands.filter {$0.isEnabled == true};
            if ctxOutside {
                selectedCar = carResp.value
                timerText = enabledTimers.count > 0 ? String(format: NSLocalizedString("%d timer(s) active", comment: "Shown under timers tab"), enabledTimers.count) : nil
                let lat = Double(carResp.value.location.lat ?? "0.0") ?? 0.0
                let lon = Double(carResp.value.location.lon ?? "0.0") ?? 0.0
                geocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon), isHome: carResp.value.location.isHome == true)
                return
            }
            withAnimation {
                selectedCar = carResp.value
                timerText = enabledTimers.count > 0 ? String(format: NSLocalizedString("%d timer(s) active", comment: "Shown under timers tab"), enabledTimers.count) : nil
                let lat = Double(carResp.value.location.lat ?? "0.0") ?? 0.0
                let lon = Double(carResp.value.location.lon ?? "0.0") ?? 0.0
                geocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon), isHome: carResp.value.location.isHome == true)
            }
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await updateCarInfo()
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
                initialLoading = true
                refreshToken = ""
                break
            }
        } catch let e {
            print(e)
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
    
    private func sendTCUCommand(_ type: Int, outside: Bool = false, args: [String:AnyJSON]? = nil) async {
        if (selectedCar?.sensitiveCommands?.contains(type) == true && selectedCar?.isCommandPinEnforced == true) {
            // show pin prompt
            selectedCar?.isCommandRequested = false
            pendingCmdType = type
            pendingCmdOutside = outside
            pendingCmdArgs = args
            
            // Check if Biometric Authentication is enabled and available
            if accountInfo?.isCommandPinSet == true && BiometricAuthManager.shared.isBiometricsEnabled && BiometricAuthManager.shared.hasStoredPin {
                let (success, pin, _) = await BiometricAuthManager.shared.authenticateAndGetPin(reason: "Authorize sensitive command")
                if success, let pin {
                    await sendTCUCommandImpl(type, outside: outside, args: args, commandPin: pin)
                    pendingCmdType = 0
                    pendingCmdOutside = false
                    pendingCmdArgs = nil
                    return
                }
            }
            
            pinErrorMsg = nil
            showPinPrompt = accountInfo?.isCommandPinSet == true
            showSetupPinPrompt = !showPinPrompt
            return
        }
        await sendTCUCommandImpl(type, outside: outside, args: args)
    }

    
    private func sendTCUCommandImpl(_ type: Int, outside: Bool = false, args: [String:AnyJSON]? = nil, commandPin: String? = nil, refreshAccountInfo: Bool = false) async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        do {
            let commandResp: Response<CommandResponse> = try await client.send(Paths.api.command.vin(lastActiveCar).post(.init(commandType: Double(type), commandPayload: args, commandPin: commandPin)))
            
            if (commandResp.value.car.isCommandRequested == false) {
                errorMsg = commandResp.value.message
                showError = true
                return
            }
            
            if (selectedCar?.smsConfig.keys.contains("provider") == true) {
                let provider = selectedCar!.smsConfig["provider"]?.value as? String
                if provider == "ondevice" {
                    let mPhoneNumber = selectedCar!.smsConfig["phone"]!.value as! String;
                    if let url = URL(string: "sms://" + mPhoneNumber + "&body=NISSAN_EVIT_TELEMATICS_CENTER") {
                        Task {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            }
            
            if outside {
                selectedCar = commandResp.value.car
            } else {
                withAnimation {
                    selectedCar = commandResp.value.car
                }
            }
            
            do {
                if (refreshAccountInfo) {
                    accountInfo = try await client.send(Paths.account.detail.get).value
                }
            } catch _ {}
        } catch let e as OCWAPIError {
            selectedCar?.isCommandRequested = false
            if (e.statusCode == 403) {
                if let commandPin {
                    // The server refused this PIN. When it is the one kept for biometrics
                    // - the PIN was changed elsewhere - forget it, so that Face ID stops
                    // handing over a PIN the server no longer accepts and the new one is
                    // asked for instead.
                    if BiometricAuthManager.shared.isStoredPin(commandPin) {
                        BiometricAuthManager.shared.removeStoredPin()
                    }
                    pinErrorMsg = e.apiError?.detail ?? e.apiError?.error ?? NSLocalizedString("Incorrect PIN, please try again", comment: "Shown in the command PIN sheet after the server rejected the PIN")
                } else {
                    pinErrorMsg = nil
                }
                pendingCmdType = type
                pendingCmdOutside = outside
                pendingCmdArgs = args
                showPinPrompt = accountInfo?.isCommandPinSet == true
                showSetupPinPrompt = !showPinPrompt
                return
            }
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await sendTCUCommandImpl(type, outside: outside, args: args, commandPin: commandPin, refreshAccountInfo: refreshAccountInfo)
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
                initialLoading = true
                refreshToken = ""
                break
            }
        } catch let e {
            print(e)
            selectedCar?.isCommandRequested = false
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
    
    private func loadInitialData() async {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        do {
            let carsResp: Response<[RestAPI.CarSerializerList]> = try await client.send(Paths.api.car.get)
            cars = carsResp.value
            do {
                carsList = String(data: (try! JSONEncoder().encode(carsResp.value)) ?? Data(), encoding: .utf8) ?? ""
            } catch let e {
                print(e)
            }
            if cars.isEmpty {
                showError = true
                errorMsg = "You don't have any cars added to your account. Please add a car first via web browser portal."
                return
            }
            
            // Send push data
            do {
                accountInfo = try await client.send(Paths.account.detail.get).value
            } catch let e {
                print("Failed to load account info!")
                print(e)
            }
            
            
            let activeCar = cars.first(where: { $0.vin == lastActiveCar }) ?? cars[0]
            lastActiveCar = activeCar.vin
            
            let carResp: Response<Car> = try await client.send(Paths.api.car.vin(lastActiveCar).get)
            
            let alertResp: Response<[AlertHistoryFull]> = try await client.send(Paths.api.alerts.vin(lastActiveCar).get)
            
            alerts = alertResp.value
            
            selectedCar = carResp.value
            let enabledTimers = carResp.value.timerCommands.filter {$0.isEnabled == true};
            timerText = enabledTimers.count > 0 ? String(format: NSLocalizedString("%d timer(s) active", comment: "Shown under timers tab"), enabledTimers.count) : nil
            let lat = Double(carResp.value.location.lat ?? "0.0") ?? 0.0
            let lon = Double(carResp.value.location.lon ?? "0.0") ?? 0.0
            geocodeCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon), isHome: carResp.value.location.isHome == true)

            withAnimation {
                initialLoading = false
            }
            
            // Send push data
            do {
                var tokenUpdatePload = TokenMetadataUpdate(refresh: refreshToken)
                tokenUpdatePload.deviceOs = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
                tokenUpdatePload.deviceType = "apple"
                tokenUpdatePload.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                tokenUpdatePload.pushNotificationKey = UserDefaults.standard.string(forKey: "APNSToken")
                try await client.send(Paths.api.token.update.post(tokenUpdatePload))
            } catch let e {
                print("Push failed!")
                print(e)
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                await loadInitialData()
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
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
        }
    }
    
    private func geocodeCoordinate(_ coordinate: CLLocationCoordinate2D, isHome: Bool = false) {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            var geocodedNewLoc = "Unknown"
            if isHome {
                geocodedNewLoc = "Home, Unknown address"
            }
            geocodedLoc = geocodedNewLoc
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let placemark = placemarks?.first {
                    print(placemark)
                    // Format the address from placemark
                    let addressComponents = [
                        placemark.subThoroughfare,    // e.g., street name
                        placemark.postalCode,      // e.g., ZIP code
                        placemark.locality,        // e.g., city
                    ]
                    
                    geocodedNewLoc = ""
                    if isHome {
                        geocodedNewLoc += "Home, "
                    }
                    
                    if let streetName = placemark.thoroughfare {
                        geocodedNewLoc = streetName+", "
                    }

                    // Filter out nil components and join them
                    geocodedNewLoc += addressComponents
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    print(geocodedNewLoc)
                    geocodedLoc = geocodedNewLoc
                    
                    constructPages()
                } else {
                    print("No address found")
                }
            }
        }
    
    private func constructPages() {
        pages = [
            HomeItemData(icon: "bolt.car.fill", text: "EV Info", subText: .constant(nil), destination: EVInfoView(car: $selectedCar, sendCommand: sendTCUCommand)),
            HomeItemData(icon: "location.fill", text: "Location", subText: $geocodedLoc, destination: LocationView(token: $accessToken, refreshToken: $refreshToken, serverUrl: $serverUrl, carLocation: $selectedCar)),
            HomeItemData(icon: "timer", text: "Timers", subText: $timerText, destination: TimersView(token: $accessToken, refreshToken: $refreshToken, serverUrl: $serverUrl, car: $selectedCar)),
            HomeItemData(icon: "bell.fill", text: "Notifications", subText: .constant(nil), destination: AlertsView(alerts: $alerts)),
        ]
        if (selectedCar?.tcuType == .continental2012) {
            pages.append(
                HomeItemData(icon: "gear", text: "TCU Settings", subText: .constant(nil), destination: TCUSettingsView(car: $selectedCar, sendCommand: sendTCUCommand)))
        }
        if (selectedCar?.tcuType == .ficosa2016) {
            pages.append(
                HomeItemData(icon: "waveform.path.ecg.rectangle", text: "Vehicle Health", subText: .constant(nil), destination: VehicleHealthView(car: $selectedCar)))
        }
    }
}

#Preview {
    MainView(refreshToken: .constant(""))
}
