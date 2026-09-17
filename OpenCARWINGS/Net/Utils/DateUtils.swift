//
//  DateUtils.swift
//  OpenCARWINGS
//
//  Created by Ruben Mkrtumyan on 29.4.2025.
//

import Foundation
import RestAPI

public struct DateUtils {
    
    static func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
    
    static func formatMinutesToHHMM(_ minutes: Int) -> String {
        if minutes == 2047 || minutes == 4095 {
            return "--:--"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%02d:%02d", hours, remainingMinutes)
    }
    
    static func formatMinutesToDuration(_ minutes: Int, _ unitsStyle: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = unitsStyle
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: TimeInterval(minutes * 60))
    }
    
    static let multipleFormats: JSONDecoder.DateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Define supported date formatters
            let formatters: [DateFormatter] = [
                createFormatter("yyyy-MM-dd'T'HH:mm:ss'Z'"),
                createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSS'Z'"),
                createFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"),
                createFormatter("yyyy-MM-dd'T'HH:mm:ss"),
                createFormatter("yyyy-MM-dd"),
            ]
            
            // Try each formatter to parse the date
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // Throw an error if no format matches
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }
    
    static func formatToLocalDate(_ date: Date?, _ timeStyle: DateFormatter.Style = .short, _ dateStyle: DateFormatter.Style = .medium, _ timeZone: TimeZone? = nil) -> String? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = TimeZone.current
        
        // Return the formatted local date
        return formatter.string(from: date)
    }
    
    static func formatToUTCTimerTime(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        
        formatter.timeZone = .none
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        
        return formatter.string(from: toGlobalTime(date))
    }
    
    static func toGlobalTime(_ date: Date) -> Date {
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let epochDate = date.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate - Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    static func toLocalTime(_ date: Date) -> Date {
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let epochDate = date.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
    
    static func parseToLocalTimerTime(_ date: String?) -> Date? {
        guard let parsedDate = parseTimerTimeString(date) else {
            return nil
        }
        return toLocalTime(parsedDate)
    }
    
    static func parseTimerTimeString(_ date: String?, _ tz: TimeZone? = nil) -> Date? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        
        formatter.timeZone = tz // User's local timezone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        
        if let date1 = formatter.date(from: date) {
            return date1
        }
        
        formatter.dateFormat = "HH:mm:ss"
        
        if let date2 = formatter.date(from: date) {
            return date2
        }
        
        return nil
    }
    
    static func parseAndFormatToLocalTimerTime(_ date: String?) -> String? {
        return formatToLocalDate(parseToLocalTimerTime(date), .short, .none)
    }
    
    static func getFullWeekdays() -> [String] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        return calendar.weekdaySymbols
    }
    
    static func formatCommandTimerDays(_ timer: CommandTimerSetting) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        let days = calendar.shortWeekdaySymbols
        var formattedStr = "";
        if timer.isWeekdayMon == true {
            formattedStr += days[1] + " | "
        }
        if timer.isWeekdayTue == true {
            formattedStr += days[2] + " | "
        }
        if timer.isWeekdayWed == true {
            formattedStr += days[3] + " | "
        }
        if timer.isWeekdayThu == true {
            formattedStr += days[4] + " | "
        }
        if timer.isWeekdayFri == true {
            formattedStr += days[5] + " | "
        }
        if timer.isWeekdaySat == true {
            formattedStr += days[6] + " | "
        }
        if timer.isWeekdaySun == true {
            formattedStr += days[0] + " | "
        }
        return formattedStr
    }
    
    static func correctDateBasedOnTimerTime(_ timer: CommandTimerSetting) -> Date? {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        guard let date = NaiveDateUtils.naiveDateToSystemDate(timer.date, utcCalendar), let parsedTime = DateUtils.parseTimerTimeString(timer.time, TimeZone(identifier: "UTC")!) else { return nil }


        let dateComponents = utcCalendar.dateComponents([.year, .month, .day], from: date)
        let timeOfDayComponents = utcCalendar.dateComponents([.hour, .minute, .second], from: parsedTime)

        var combinedComponents = dateComponents
        combinedComponents.hour = timeOfDayComponents.hour
        combinedComponents.minute = timeOfDayComponents.minute
        combinedComponents.second = timeOfDayComponents.second
        combinedComponents.timeZone = TimeZone(identifier: "UTC")!

        guard let instant = utcCalendar.date(from: combinedComponents) else { return nil }
        
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone.current
        
        let localDateComponents = localCalendar.dateComponents([.year, .month, .day], from: instant)
        return localCalendar.date(from: localDateComponents)
    }
    
    static func correctDateSelectionToUTC(_ dateSelection: Date?, _ timeSelection: Date?) -> Date? {
        guard let date = dateSelection, let time = timeSelection else { return nil }

        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = TimeZone.current
        let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: date)

        let timeOfDayComponents = localCalendar.dateComponents([.hour, .minute, .second], from: time)

        var combinedComponents = dateComponents
        combinedComponents.hour = timeOfDayComponents.hour
        combinedComponents.minute = timeOfDayComponents.minute
        combinedComponents.second = timeOfDayComponents.second
        combinedComponents.timeZone = TimeZone.current

        guard let instant = localCalendar.date(from: combinedComponents) else { return nil }

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let utcDateComponents = utcCalendar.dateComponents([.year, .month, .day], from: instant)
        return utcCalendar.date(from: utcDateComponents)
    }
}
