//
//  BundleUtils.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 24.8.2026.
//
import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
