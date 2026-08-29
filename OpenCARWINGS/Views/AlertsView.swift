//
//  AlertsView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import RestAPI

struct AlertsView: View {
    @Binding var alerts: [AlertHistoryFull]
    var body: some View {
        List {
            ForEach(alerts, id: \.id) {alert in
                VStack(alignment: .leading) {
                    Text(alert.typeDisplay).font(.title3)
                    if let msg = alert.additionalData {
                        Text(msg)
                    }
                    Text(DateUtils.formatToLocalDate(alert.timestamp) ?? "").font(.caption)
                }
            }
        }.navigationTitle(Text("Notifications"))
    }
}

#Preview {
    AlertsView(alerts: .constant([]))
}
