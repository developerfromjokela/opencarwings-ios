//
//  PageHeader.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import RestAPI

struct PageHeader: View {
    @Binding var selectedCar: Car?
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                let soc: Double = selectedCar?.evInfo.socDisplay ?? selectedCar?.evInfo.soc ?? 0.0
                Text(String(format: "%.1f", Double(round(10 * (soc))/10))+"%")
                    .font(.title3)
                HStack {
                    if selectedCar?.isCommandRequested == true {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())                             .scaleEffect(0.8)
                    }
                    Text(LocalizedStringKey(selectedCar?.evInfo.isAcStatus == true ? "Cabin preconditioning" :  (selectedCar?.evInfo.isQuickCharging ?? true ? "Quick-charging" : (selectedCar?.evInfo.isCharging == true ? "Charging" : String(format: ((selectedCar?.evInfo.isCarRunning == true &&  selectedCar?.evInfo.carGear == 0) ? "On (%@)" : "%@"), selectedCar?.evInfo.carGear == 0 ? "Parked" : "Driving")))))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal).padding(.leading, 10)
    }
}

#Preview {
    PageHeader(selectedCar: .constant(nil))
}
