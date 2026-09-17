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
    
    private var statusText: String {
        guard let evInfo = selectedCar?.evInfo else {
            return NSLocalizedString("Parked", comment: "Default status")
        }
        
        if evInfo.isAcStatus == true {
            return NSLocalizedString("Cabin preconditioning", comment: "")
        }
        
        if evInfo.isQuickCharging ?? true {
            return NSLocalizedString("Quick-charging", comment: "")
        }
        
        if evInfo.isCharging == true {
            var estimate: Int? = nil
            
            if evInfo.limitChgTime != 2047 && evInfo.limitChgTime != 4097 {
                estimate = evInfo.limitChgTime
            }
            if evInfo.fullChgTime != 2047 && evInfo.fullChgTime != 4097 {
                estimate = evInfo.fullChgTime
            }
            if evInfo.obc6kw != 2047 && evInfo.obc6kw != 4097 && evInfo.isObc6kwAvail == true {
                estimate = evInfo.obc6kw
            }
            
            if let estimate = estimate, let formattedDuration = DateUtils.formatMinutesToDuration(estimate) {
                let formatString = NSLocalizedString("Charging, ~%@ left", comment: "Charging with remaining time estimate")
                return String(format: formatString, formattedDuration)
            } else {
                return NSLocalizedString("Charging", comment: "Charging status without estimate")
            }
        }
        
        if evInfo.isCarRunning == true && evInfo.carGear == 0 {
            return String(format: NSLocalizedString("On (%@)", comment: ""), NSLocalizedString("Parked", comment: ""))
        }
        
        return evInfo.carGear == 0 ? NSLocalizedString("Parked", comment: "") : NSLocalizedString("Driving", comment: "")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                let soc: Double = selectedCar?.evInfo.socDisplay ?? selectedCar?.evInfo.soc ?? 0.0
                Text(String(format: "%.1f%%", round(10 * soc) / 10))
                    .font(.title3)
                
                HStack {
                    if selectedCar?.isCommandRequested == true {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.leading, 10)
    }
}

#Preview {
    PageHeader(selectedCar: .constant(nil))
}
