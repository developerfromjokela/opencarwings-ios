//
//  TCUSettingsView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import RestAPI

struct TCUSettingsView: View {
    @Binding var car: Car?
    var sendCommand: (Int, Bool, [String:AnyJSON]?) async -> Void
    var body: some View {
        List {
            if car?.isCommandRequested == true && car?.commandType == 5 {
                VStack(alignment: .center, spacing: 3) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Text("Refreshing...")
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            }
            VStack(alignment: .leading) {
                Text("PPP Number").font(.subheadline)
                Text(car?.tcuConfiguration.dialCode ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("APN").font(.subheadline)
                Text(car?.tcuConfiguration.apn ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("PPP Username").font(.subheadline)
                Text(car?.tcuConfiguration.apnUser ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("PPP Password").font(.subheadline)
                Text(car?.tcuConfiguration.apnPassword ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("DNS1").font(.subheadline)
                Text(car?.tcuConfiguration.dns1 ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("DNS2").font(.subheadline)
                Text(car?.tcuConfiguration.dns2 ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("Server Hostname").font(.subheadline)
                Text(car?.tcuConfiguration.serverURL ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("Proxy Hostname").font(.subheadline)
                Text(car?.tcuConfiguration.proxyURL ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("Connection type").font(.subheadline)
                Text(car?.tcuConfiguration.connectionType ?? "N/A")
            }
            VStack(alignment: .leading) {
                Text("Last updated").font(.subheadline)
                Text(DateUtils.formatToLocalDate(car?.tcuConfiguration.lastUpdated) ?? "never")
            }
        }.refreshable {
            await sendCommand(5, true, nil)
        }.navigationTitle(Text("TCU Settings"))
    }
}

#Preview {
    TCUSettingsView(car: .constant(nil), sendCommand: {_,_,_  in})
}
