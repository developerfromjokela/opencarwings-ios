//
//  RangeDisplay.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import SwiftUI
import RestAPI

struct RangeDisplay: View {
    @Binding var selectedCar: Car?
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                Text(formatDistance(Measurement(value: Double(selectedCar?.evInfo.rangeAcon ?? 0), unit: UnitLength.kilometers)))
                    .font(.title3).padding(.bottom, -5)
                Image(systemName: "fanblades.fill").resizable().scaledToFit().frame(width: 15, height: 15)
            }.padding(.horizontal, 20)
            VStack(alignment: .center) {
                Text(formatDistance(Measurement(value: Double(selectedCar?.evInfo.rangeAcoff ?? 0), unit: UnitLength.kilometers)))
                    .font(.title3).padding(.bottom, -5)
                OffIconView(imageName: "fanblades", size: 15)
            }
        }.frame(alignment: .center).padding(.bottom)
    }
}

#Preview {
    RangeDisplay(selectedCar: .constant(nil))
}
