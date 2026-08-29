//
//  SignInView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import Get
import RestAPI
import OSInfo

struct SignInView: View {
    private let servers = ["opencarwings.viaaq.eu", "custom"]
    @State private var selectedServer = "opencarwings.viaaq.eu"
    @State private var customServerUrl: String = ""
    @State private var isURLValid = false

    @KeychainStorage("ocw_username") private var username: String = ""
    @KeychainStorage("ocw_password") private var password: String = ""
    @KeychainStorage("ocw_server") private var serverUrl: String = ""
    @Binding var refreshToken: String
    @KeychainStorage("ocw_access_token") private var accessToken: String = ""
    
    @State private var showProgress: Bool = false
    @State private var showError = false
    @State private var errorMsg: String = ""
    @State private var otpCode: String? = nil
    @State private var showOtpPrompt = false

    var body: some View {
        VStack {
            Form {
                VStack(alignment: .center) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color(.systemGroupedBackground))
                .background(Color(.systemGroupedBackground))
                .listRowSeparator(.hidden)
                
                Section {
                    VStack {
                        Picker("Server", selection: $selectedServer) {
                            ForEach(servers, id: \.self) { category in
                                Text(category)
                            }
                        }
                        // Default style (.menu) is ideal for forms
                        .pickerStyle(.menu)
                        
                        if selectedServer == "custom" {
                            TextField("Enter custom server URL", text: $customServerUrl)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: customServerUrl) { newValue in
                                    // Basic URL validation
                                    isURLValid = isValidURL(newValue)
                                }.frame(width: .infinity)
                            
                            if !isURLValid && !customServerUrl.isEmpty {
                                Text("Please enter a valid URL")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                Section {
                    TextField(
                        "Username",
                         text: $username
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }
                Section {
                    SecureField(
                        "Password",
                         text: $password
                    )
                }
                Link("Forgot password?", destination: URL(string: isURLValid ? (formatPageFromUrl(path: "password-reset")) : ("https://"+selectedServer+"/password-reset/")) ?? URL(string: "https://opencarwings.viaaq.eu/password-reset/")!)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .listRowBackground(Color(.systemGroupedBackground))
                        .background(Color(.systemGroupedBackground))
                        .listRowSeparator(.hidden)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                

            }.listSectionSpacing(.compact).sheet(isPresented: $showOtpPrompt) {
                OtpSheetView(onSubmit: { code in
                    otpCode = code
                    showOtpPrompt = false
                    if (showProgress) {
                        return
                    }
                    Task {
                        await signIn()
                    }
                })
            }
            LargeButton(title: "Sign In", disabled: .constant(username == "" || password == "" || (selectedServer == "custom" && !isURLValid)), backgroundColor: .accentColor, action: signIn).padding()
                .listRowBackground(Color(.systemGroupedBackground))
                .background(Color(.systemGroupedBackground))
                .listRowSeparator(.hidden)
        }.listRowBackground(Color(.systemGroupedBackground))
            .background(Color(.systemGroupedBackground))
            .listRowSeparator(.hidden).loadingDialog(isPresented: $showProgress, message: "Signing in...")  .alert(LocalizedStringKey(errorMsg),
                                                                                                                   isPresented: $showError) {
                                                                                                                 }


    }
    
    private func signIn() async {
        showProgress = true
        var url = "https://"+selectedServer;
        if selectedServer == "custom" && isURLValid {
            url = customServerUrl
        }
        let client = OCWAPIClientFactory.createAPIClient(url)
        
        do {
            var pload = JWTTokenObtainPair(
                deviceType: "apple", deviceOs: "\(OS.current.name) \(OS.current.displayVersion)",
                appVersion:Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                pushNotificationKey: UserDefaults.standard.string(forKey: "APNSToken"),
                username: username, password: password
            )
            
            if (otpCode != nil && otpCode?.isEmpty == false) {
                pload.otpCode = otpCode
            }
            
            print(pload)
            
            otpCode = nil
            let authresult: Response<JWTTokenLogin>  = try await client.send(Paths.api.token.obtain.post(pload))
            serverUrl = url
            showProgress = false
            withAnimation {
                accessToken = authresult.value.access ?? ""
                refreshToken = authresult.value.refresh
            }
            print(authresult)
        }
        catch let e as OCWAPIError {
            showProgress = false
            if e.statusCode == 401 {
                print(e.apiError)
                if (e.apiError?.detail?.starts(with: "otp_code") == true) {
                    showOtpPrompt = true
                    return
                }
                // Usr/Pw fail
                showError = true
                errorMsg = e.apiError?.detail ?? e.apiError?.error ?? "Invalid username or password";
            } else if e.statusCode == 503 {
                showError = true
                errorMsg = "Server is unavailable. Please try again later.";
            } else {
                showError = true
                errorMsg = "Server error (\(e.statusCode))";
            }
        }
        catch let e {
            print(type(of: e))
            showProgress = false
            showError = true
            errorMsg = "Cannot connect to server. Please try again later.";
            print(e)
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard !string.isEmpty else { return true } // Allow empty field
        let urlPattern = "^(https?://)?([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", urlPattern)
        return predicate.evaluate(with: string)
    }
    
    private func formatPageFromUrl(path: String) -> String {
        return customServerUrl.isEmpty ? "" : URL(string: customServerUrl)!.appendingPathComponent(path).absoluteString
    }
}

#Preview {
    SignInView(refreshToken: .constant(""))
}
