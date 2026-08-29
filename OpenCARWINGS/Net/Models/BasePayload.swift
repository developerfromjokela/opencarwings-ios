//
//  BasePayload.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation

public struct BasePayload: Codable, Hashable {
    var success: Bool?;
    var type: String;
}
