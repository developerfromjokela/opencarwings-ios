//
//  DTC_Code.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 19.8.2026.
//
import Foundation
import NaiveDate

public struct DTC_Code: Codable, Identifiable {
    public let id: UUID
    
    public var ecuId: Int
    public var ecuLabel: String?
    public var codeLabel: String
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.ecuId = try values.decode(Int.self, forKey: "ecu_id")
        self.ecuLabel = try? values.decodeIfPresent(String.self, forKey: "ecu_label")
        self.codeLabel = try values.decode(String.self, forKey: "code_label")
        self.id = UUID()
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(ecuId, forKey: "ecu_id")
        try values.encodeIfPresent(ecuLabel, forKey: "ecu_label")
        try values.encode(codeLabel, forKey: "code_label")
    }
}
