//
//  CarInfoBlock.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import RestAPI

struct CarInfoBlock: View {
    @Binding var car: Car?
    @State private var carType = "LEAF ZE0"

    var body: some View {
        VStack(alignment: .leading) {
            Text("Nissan \(carType)").font(.title3).bold()
            Text(car?.vin ?? "No VIN").font(.caption)
            Text(formatDistance(Measurement(value: Double(car?.odometer ?? 0), unit: UnitLength.kilometers))).font(.caption)
            Text("TCU ID: "+(car?.tcuModel ?? "----")).font(.caption)
            Text("Navi ID: "+(car?.tcuSerial ?? "----")).font(.caption)
            Text("TCU Software: \((car?.tcuVer ?? "----"))").font(.caption)
            Text("SOH: \(car?.evInfo.soh ?? 0)%").font(.caption)
            if (car?.tcuVer != "TCU033") {
                Text("Capacity bars: \(car?.evInfo.capBars ?? 0)/12").font(.caption)
            }
            Text("Battery pack capacity: \(String(format: "%.2f", self.getKwhCapacity(car?.evInfo))) kWh").font(.caption)
            Text("Last Updated \(DateUtils.formatToLocalDate(car?.lastConnection) ?? "never")").font(.caption).padding(.top, 4)
        }.frame(maxWidth: .infinity, alignment: .leading).onChange(of: car?.tcuVer) {
            setCarModel()
        }.onAppear {
            setCarModel()
        }
    }
    
    private func getKwhCapacity(_ evInfo: EVInfo?) -> Double {
        let kWhNew = ((evInfo?.maxGids ?? 0) * 80)
        let soh = Double(evInfo?.soh ?? 0)/100.0
        return (Double(kWhNew)*soh)/1000.0
    }
    
    private func setCarModel() {
        if (car?.vin.starts(with: "VSK") == true) {
            carType = "e-NV200 24 kWh"
            if car?.tcuVer == "TCU033" {
                carType = "e-NV200 40 kWh"
            }
            return
        }
        if car?.tcuVer == "06.42" || car?.tcuVersion == "06.42" {
            carType = "LEAF AZE0"
        }
        if car?.tcuVer == "TCU033" {
            carType = "LEAF ZE1"
        }
        if car?.tcuVer == "TCU032" {
            carType = "LEAF AZE0 24/30 kWh (2016-27)"
        }
    }
}

#Preview {
    CarInfoBlock(car: .constant(nil))
}
