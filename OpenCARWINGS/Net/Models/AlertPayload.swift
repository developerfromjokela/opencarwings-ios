//
//  AlertPayload.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 30.4.2025.
//

import Foundation
import RestAPI

struct AlertPayload: Codable {
    var data: AlertHistoryFull
}
