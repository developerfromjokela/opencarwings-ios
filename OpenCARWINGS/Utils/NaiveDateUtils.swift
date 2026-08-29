//
//  NaiveDateUtils.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 23.8.2026.
//

import NaiveDate
import Foundation

public struct NaiveDateUtils {
    
    public static func naiveDateToSystemDate(_ date: NaiveDate?, _ calendar: Calendar = .current) -> Date? {
        guard let date = date else {return nil}
        return calendar.date(from: date)
    }
}
