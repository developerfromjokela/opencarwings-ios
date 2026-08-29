//
//  EVInfoView.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import SwiftUI
import RestAPI


// MARK: - Root screen

struct VehicleHealthView: View {
    @Binding var car: Car?

    @Environment(\.dismiss) private var dismiss

    private enum Tab: String, CaseIterable, Identifiable {
        case tirePressure = "tpms"
        case dtcCodes = "dtc"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .tirePressure: return "tire"
            case .dtcCodes: return "exclamationmark.warninglight.fill"
            }
        }
    }

    @State private var selectedTab: Tab = .tirePressure


    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                TirePressureTab(car: $car)
                    .tabItem {
                        Label(LocalizedStringKey("Tire Pressure"), systemImage: Tab.tirePressure.icon)
                    }
                    .tag(Tab.tirePressure)

                DTCCodesTab(car: $car)
                    .tabItem {
                        Label(LocalizedStringKey("DTC Codes"), systemImage: Tab.dtcCodes.icon)
                    }
                    .tag(Tab.dtcCodes)
            }

        }.navigationTitle(Text("Vehicle Health"))
    }
}

// MARK: - Tire Pressure Tab

private struct TirePressureTab: View {
    @Binding var car: Car?


    private var timestampText: String {
        return DateUtils.formatToLocalDate(car?.vehHealth?.lastUpdated) ?? "--"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text(timestampText)
                        .font(.system(size: 15, weight: .medium))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)

            GeometryReader { geo in
                ZStack {
                    Image("o_"+(car?.color?.rawValue ?? "l_vividblue"))
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width * 0.50)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    pressureLabel(car?.vehHealth?.tpmsFl ?? 0, alignment: .topLeading, geo: geo)
                    pressureLabel(car?.vehHealth?.tpmsFr ?? 0, alignment: .topTrailing, geo: geo)
                    pressureLabel(car?.vehHealth?.tpmsRl ?? 0, alignment: .bottomLeading, geo: geo)
                    pressureLabel(car?.vehHealth?.tpmsRr ?? 0, alignment: .bottomTrailing, geo: geo)
                    
                    // TPMS warning telltale
                    if car?.vehHealth?.isTpmsLight == true {
                        Image(systemName: "exclamationmark.tirepressure")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.yellow)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.top, 36)
                            .padding(.leading, 4)
                    }

                    // Center glass info card
                    if #available(iOS 26.0, *) {
                        infoCard
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                    } else {
                        infoCardOld
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    @available(iOS 26.0, *)
    private var infoCard: some View {
        var mileage: String = "--"
        if (car?.vehHealth?.mileage ?? 0 > 0) {
            mileage = formatDistance(Measurement(value: Double(car?.vehHealth?.mileage ?? 0), unit: UnitLength.kilometers))
        }
        return VStack(spacing: 10) {
            Text("Mileage: \(mileage)")
                .font(.system(size: 17, weight: .medium))
            Text("Maintenance Alert: \(car?.vehHealth?.isMaintenanceAlert == true ? "Yes" : "No")")
                .font(.system(size: 17, weight: .medium))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
    
    private var infoCardOld: some View {
        var mileage: String = "--"
        if (car?.vehHealth?.mileage ?? 0 > 0) {
            mileage = String(car?.vehHealth?.mileage ?? 0)+" km"
        }
        return VStack(spacing: 10) {
            Text("Mileage: \(mileage)")
                .font(.system(size: 17, weight: .medium))
            Text("Maintenance Alert: \(car?.vehHealth?.isMaintenanceAlert == true ? "Yes" : "No")")
                .font(.system(size: 17, weight: .medium))
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private func pressureLabel(_ value: Int, alignment: Alignment, geo: GeometryProxy) -> some View {
        Text("\(value) kPa")
            .font(.system(size: 22, weight: .semibold))
            .frame(
                maxWidth: .infinity, maxHeight: .infinity,
                alignment: alignment
            )
            .padding(alignment == .topLeading || alignment == .bottomLeading ? .leading : .trailing, 8)
            .padding(alignment == .topLeading || alignment == .topTrailing ? .top : .bottom, 8)
    }
}

// MARK: - DTC Codes Tab

private struct DTCCodesTab: View {
    @Binding var car: Car?

    private var codes: [DTC_Code] {
        (car?.vehHealth?.dtcLong ?? []) + (car?.vehHealth?.dtcShort ?? [])
    }

    var body: some View {
        Group {
            if codes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(codes) { dtc in
                            DTCRow(dtc: dtc)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
            Text(LocalizedStringKey("No fault codes reported"))
                .font(.system(size: 16, weight: .medium))
        }
    }
}

private struct DTCRow: View {
    let dtc: DTC_Code

    var body: some View {
        if #available(iOS 26.0, *) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dtc.ecuLabel ?? String(format: NSLocalizedString("ECU %04X", comment: "DTC Code ECU ID"), dtc.ecuId))
                        .font(.system(size: 19, weight: .semibold))
                        .textSelection(.enabled)
                    Text(dtc.codeLabel)
                        .font(.system(size: 16, weight: .regular))
                        .textSelection(.enabled)
                }
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(dtc.ecuLabel ?? String(format: NSLocalizedString("ECU %04X", comment: "DTC Code ECU ID"), dtc.ecuId))
                        .font(.system(size: 19, weight: .semibold))
                        .textSelection(.enabled)
                    Text(dtc.codeLabel)
                        .font(.system(size: 16, weight: .regular))
                        .textSelection(.enabled)
                }
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
        }
    }
}
