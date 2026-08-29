//
//  CarWidget.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 31.12.2025.
//

import WidgetKit
import SwiftUI
import AppIntents
import RestAPI
import Get


struct CarEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Car"
    static var defaultQuery = CarQuery()
    
    typealias ID = String
    
    let id: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    var name: String
}

enum RangeDisplayEnum: String, AppEnum {
    static var caseDisplayRepresentations: [RangeDisplayEnum : DisplayRepresentation] = [
        .soc: DisplayRepresentation(title: "State Of Charge"),
        .rangeAcOn: DisplayRepresentation(title: "Range (A/C On)"),
        .rangeAcOff: DisplayRepresentation(title: "Range (A/C Off)"),
        .bars:DisplayRepresentation(title: "Charge Bars")
    ]
    
    case rangeAcOn = "raon"
    case rangeAcOff = "raoff"
    case soc = "soc"
    case bars = "bars"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Range Display"
    
    var displayRepresentation: DisplayRepresentation {
        switch self {
        case .rangeAcOn:
            DisplayRepresentation(title: "Range (A/C On)")
        case .rangeAcOff:
            DisplayRepresentation(title: "Range (A/C Off)")
        case .soc:
            DisplayRepresentation(title: "State Of Charge")
        case .bars:
            DisplayRepresentation(title: "Charge Bars")
        }
    }
}

struct CarQuery: EntityQuery {
    @KeychainStorage("cars_list") private var carsList: String = ""

    
    func entities(for identifiers: [CarEntity.ID]) async throws -> [CarEntity] {
        let allCars = loadCarsFromAppGroup()
        return allCars.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [CarEntity] {
        return loadCarsFromAppGroup()  // Return all available cars
    }
    
    func defaultResult() async -> CarEntity? {
        return loadCarsFromAppGroup().first  // Optional: default to first car
    }
    
    private func loadCarsFromAppGroup() -> [CarEntity] {
        let decoder = JSONDecoder()
        guard let cars = try? decoder.decode([CarSerializerList].self, from: carsList.data(using: .utf8) ?? Data()) else {return []}
        return cars.map {CarEntity(id: $0.vin, name: $0.nickname ?? $0.vin)}
    }
}

struct SelectCarIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Car"
    static var description = IntentDescription("Choose which car to show in the widget")
    
    @Parameter(title: "Car")
    var car: CarEntity?
    
    @Parameter(title: "Range Display", default: RangeDisplayEnum.soc)
    var rangeDisplay: RangeDisplayEnum
}

struct Provider: AppIntentTimelineProvider {
    @KeychainStorage("ocw_username") private var username: String = ""
    @KeychainStorage("ocw_access_token") private var accessToken: String = ""
    @KeychainStorage("ocw_refresh_token") var refreshToken: String = ""
    @KeychainStorage("ocw_server") private var serverUrl: String = "https://opencarwings.viaaq.eu"
    
    func placeholder(in context: Context) -> CarChargeEntry {
        CarChargeEntry(date: Date(), chargePercentage: 75, carName: "My Car", carType: "Leaf", dispMode: .soc, bars: 6, unit: "", range: "", isCharging: true)
    }
    
    func snapshot(for configuration: SelectCarIntent, in context: Context) async -> CarChargeEntry {
        guard let selectedCar = configuration.car else {
            // Fallback if no car selected
            let entry = CarChargeEntry(date: Date(), chargePercentage: 0.0, carName: "No Car Selected", dispMode: .soc, bars: 0, unit: "km", range: "70", isCharging: false)
            return entry
        }
        let units = usingMile() ? "mi" : "km"
        do {
            let carInfo = try await loadCarData(vin: selectedCar.id)
            var km = 0
            if (configuration.rangeDisplay == .rangeAcOn || configuration.rangeDisplay == .rangeAcOff) {
                if (configuration.rangeDisplay == .rangeAcOn) {
                    km = Int(correctUnits(Measurement(value: Double(carInfo.evInfo.rangeAcon ?? 0), unit: UnitLength.kilometers)).value)
                }
                if (configuration.rangeDisplay == .rangeAcOff) {
                    km = Int(correctUnits(Measurement(value: Double(carInfo.evInfo.rangeAcoff ?? 0), unit: UnitLength.kilometers)).value)
                }
            }
            let entry = CarChargeEntry(date: Date(), chargePercentage: (carInfo.evInfo.socDisplay ?? carInfo.evInfo.soc) ?? 0.0, carName: carInfo.nickname ?? carInfo.vin,
                                       carType: carInfo.color?.rawValue.starts(with: "l2_") == true ? "LeafZE1" : "Leaf",dispMode: configuration.rangeDisplay, bars: carInfo.evInfo.chargeBars ?? 0, unit: units, range: "\(km)", isCharging: carInfo.evInfo.isCharging ?? carInfo.evInfo.isQuickCharging ?? false)
            
            return entry
        } catch {
            let entry = CarChargeEntry(date: Date(), chargePercentage: 0.0, carName: selectedCar.name, carType: selectedCar.id.contains("ZE1") == true ? "LeafZE1" : "Leaf", dispMode: configuration.rangeDisplay, bars: 0, unit: units, range: "--", isCharging: false)
            return entry
        }
    }
    
    func timeline(for configuration: SelectCarIntent, in context: Context) async -> Timeline<CarChargeEntry> {
        guard let selectedCar = configuration.car else {
            // Fallback if no car selected
            let entry = CarChargeEntry(date: Date(), chargePercentage: 0.0, carName: "No Car Selected", dispMode: .soc, bars: 0, unit: "km", range: "70", isCharging: false)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60*15)))
        }
        let units = usingMile() ? "mi" : "km"
        do {
            let carInfo = try await loadCarData(vin: selectedCar.id)
            var km = 0
            if (configuration.rangeDisplay == .rangeAcOn || configuration.rangeDisplay == .rangeAcOff) {
                if (configuration.rangeDisplay == .rangeAcOn) {
                    km = Int(correctUnits(Measurement(value: Double(carInfo.evInfo.rangeAcon ?? 0), unit: UnitLength.kilometers)).value)
                }
                if (configuration.rangeDisplay == .rangeAcOff) {
                    km = Int(correctUnits(Measurement(value: Double(carInfo.evInfo.rangeAcoff ?? 0), unit: UnitLength.kilometers)).value)
                }
            }
            let entry = CarChargeEntry(date: Date(), chargePercentage: (carInfo.evInfo.socDisplay ?? carInfo.evInfo.soc) ?? 0.0, carName: carInfo.nickname ?? carInfo.vin,
                                       carType: carInfo.color?.rawValue.starts(with: "l2_") == true ? "LeafZE1" : "Leaf",dispMode: configuration.rangeDisplay, bars: carInfo.evInfo.chargeBars ?? 0, unit: units, range: "\(km)", isCharging: carInfo.evInfo.isCharging ?? carInfo.evInfo.isQuickCharging ?? false)
            
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 60, to: Date())!
            return Timeline(entries: [entry], policy: .after(nextRefresh))
        } catch {
            let entry = CarChargeEntry(date: Date(), chargePercentage: 0.0, carName: selectedCar.name, carType: selectedCar.id.contains("ZE1") == true ? "LeafZE1" : "Leaf", dispMode: configuration.rangeDisplay, bars: 0, unit: units, range: "--", isCharging: false)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60*5)))
        }
    }
    
    private func loadCarData(vin: String) async throws -> Car {
        let client = OCWAPIClientFactory.createAPIClient(serverUrl, accessToken)
        
        do {
            let carResp: Response<Car> = try await client.send(Paths.api.car.vin(vin).get)
            return carResp.value
        } catch let e as OCWAPIError {
            let autCheckResult = await SessionHandler.checkAndRenewSession(client, e, refreshToken, accessToken)
            switch autCheckResult {
            case let .ok(newToken):
                accessToken = newToken?.access ?? ""
                refreshToken = newToken?.refresh ?? ""
                return try await loadCarData(vin: vin)
            case let .error(error):
                throw error
            case .invalidRefreshToken:
                refreshToken = ""
                throw e
            }
        }
    }
    
}

// 4. Updated Entry (optional: add car name for display)
struct CarChargeEntry: TimelineEntry {
    var date: Date
    var chargePercentage: Double
    var carName: String = "My Car"  // Optional, for title
    var carType: String = "Leaf"
    var dispMode: RangeDisplayEnum
    var bars: Int
    var unit: String
    var range: String
    var isCharging: Bool
}

struct CarChargeWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .accessoryRectangular {
            ZStack {

                
                VStack(alignment: .leading, spacing: 0) {
                    // Top section with icon and percentage
                    HStack(spacing: 6) {
                        Image(entry.carType)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        HStack(spacing: 3) {
                            if entry.isCharging {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            if entry.dispMode == .soc {
                                Text("\(Int(entry.chargePercentage))%")
                                    .font(.system(size: 16, weight: .semibold))
                            } else if (entry.dispMode == .bars) {
                                Text("\(Int(entry.bars)) / 12")
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Text("\(entry.range) \(entry.unit)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Car name
                    Text(entry.carName)
                        .font(.system(size: 18, weight: .bold))
       
                    
                    Spacer()
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                            
                            // Progress fill
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * (entry.chargePercentage/100))
                        }
                    }
                    .frame(height: 5)
                }
                .padding(2)
            }
        }
    }
}

struct CarChargeWidget: Widget {
    let kind: String = "CarChargeWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCarIntent.self,
            provider: Provider()
        ) { entry in
            CarChargeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("EV Battery")
        .description("Shows selected car's battery information.")
        .supportedFamilies([
            .accessoryRectangular
        ])
    }
}
