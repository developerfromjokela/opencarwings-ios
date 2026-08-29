//
//  DistanceUtils.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 20.8.2026.
//

import Foundation


func usingMile() -> Bool {
    let locale = Locale.current
    if locale.measurementSystem == .uk || locale.measurementSystem == .us{
        return true
    }
    return false
}


func correctUnits(_ value: Measurement<Dimension>) -> Measurement<Dimension> {
    if usingMile() {
        return value.converted(to: UnitLength.miles)
    }
    return value
}

func correctTemps(_ value: Measurement<UnitTemperature>) -> Measurement<UnitTemperature> {
    return value.converted(to: .init(forLocale: Locale.current))
}

func formatDistance(_ value: Measurement<Dimension>) -> String {
    let converted = correctUnits(value)
    return converted.formatted(.measurement(width: .abbreviated, usage: .general, numberFormatStyle: .number.precision(.fractionLength(0))))
}


func formatTemp(_ value: Measurement<UnitTemperature>) -> String {
    let converted = correctTemps(value)
    return converted.formatted(.measurement(width: .abbreviated, usage: .weather))
}
