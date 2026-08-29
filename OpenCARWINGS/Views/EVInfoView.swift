//
//  EVInfoView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import RestAPI

struct EVInfoView: View {
    @Binding var car: Car?
    var sendCommand: (Int, Bool, [String:AnyJSON]?) async -> Void
    var body: some View {
        List {
            if car?.isCommandRequested == true && car?.commandType == 1 {
                VStack(alignment: .center, spacing: 3) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Text("Refreshing...")
                }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            }
            VStack(alignment: .leading) {
                Text("Car running").font(.subheadline)
                Text(car?.evInfo.isCarRunning ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("Gear").font(.subheadline)
                Text(car?.evInfo.carGear == 0 ? "Park" : car?.evInfo.carGear == 1 ? "Drive" : "Reverse")
            }
            VStack(alignment: .leading) {
                Text("Charge time (120V/L1/US)").font(.subheadline)
                Text(DateUtils.formatMinutesToHHMM(car?.evInfo.limitChgTime ?? 2047))
            }
            VStack(alignment: .leading) {
                Text("Charge time (240V/L2/EU)").font(.subheadline)
                Text(DateUtils.formatMinutesToHHMM(car?.evInfo.fullChgTime ?? 2047))
            }
            VStack(alignment: .leading) {
                Text("Charge time (6.6kW)").font(.subheadline)
                Text(DateUtils.formatMinutesToHHMM(car?.evInfo.obc6kw ?? 4097))
            }
            VStack(alignment: .leading) {
                Text("Charge bars").font(.subheadline)
                Text("\(car?.evInfo.chargeBars ?? 0) / 12")
            }
            VStack(alignment: .leading) {
                Text("Capacity bars").font(.subheadline)
                Text("\(car?.evInfo.capBars ?? 0) / 12")
            }
            VStack(alignment: .leading) {
                Text("State of Charge (display)").font(.subheadline)
                Text("\(String(format: "%.2f", car?.evInfo.socDisplay ?? 0)) %")
            }
            VStack(alignment: .leading) {
                Text("State of Charge (nominal)").font(.subheadline)
                Text("\(String(format: "%.2f", car?.evInfo.soc ?? 0)) %")
            }
            
            VStack(alignment: .leading) {
                Text("State of Health").font(.subheadline)
                Text("\(car?.evInfo.soh ?? 0) %")
            }
            
            VStack(alignment: .leading) {
                Text("Remaining charge").font(.subheadline)
                Text("\(String(format: "%.2f", (car?.evInfo.whContent ?? 0.0)/1000)) kWh")
            }
            VStack(alignment: .leading) {
                Text("Estimated range (A/C on)").font(.subheadline)
                Text(formatDistance(Measurement(value: Double(car?.evInfo.rangeAcon ?? 0), unit: UnitLength.kilometers)))
            }
            VStack(alignment: .leading) {
                Text("Estimated range (A/C off)").font(.subheadline)
                Text(formatDistance(Measurement(value: Double(car?.evInfo.rangeAcoff ?? 0), unit: UnitLength.kilometers)))
            }
            VStack(alignment: .leading) {
                Text("Connected to charger").font(.subheadline)
                Text(car?.evInfo.isPluggedIn ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("Is charging").font(.subheadline)
                Text(car?.evInfo.isCharging ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("Is Quick-charging").font(.subheadline)
                Text(car?.evInfo.isQuickCharging ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("Charging finished").font(.subheadline)
                Text(car?.evInfo.isChargeFinish ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("A/C").font(.subheadline)
                Text(car?.evInfo.isAcStatus ?? false ? "Yes" : "No")
            }
            VStack(alignment: .leading) {
                Text("Remaining GIDs").font(.subheadline)
                Text(String(car?.evInfo.gids ?? 0))
            }
            VStack(alignment: .leading) {
                Text("Counter").font(.subheadline)
                Text(String(car?.evInfo.counter ?? 0))
            }
            VStack(alignment: .leading) {
                Text("Param21").font(.subheadline)
                Text(String(car?.evInfo.param21 ?? 0))
            }
            VStack(alignment: .leading) {
                Text("Last updated").font(.subheadline)
                Text(DateUtils.formatToLocalDate(car?.evInfo.lastUpdated) ?? "never")
            }
        }.refreshable {
            await sendCommand(1, true, nil)
        }.navigationTitle(Text("EV Info"))
    }
}

#Preview {
    EVInfoView(car: .constant(nil), sendCommand: {_,_,_ in})
}
