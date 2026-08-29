//
//  ContentView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI

struct ContentView: View {
    @KeychainStorage("ocw_refresh_token") private var signedIn: String = ""
    var body: some View {
        if signedIn == "" {
            SignInView(refreshToken: $signedIn)
        } else {
            MainView(refreshToken: $signedIn)
        }
    }
}

#Preview {
    ContentView()
}
