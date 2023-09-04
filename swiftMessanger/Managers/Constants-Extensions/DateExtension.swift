//
//  DateExtension.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 7.08.2023.
//

import Foundation


extension Int {
    func toDate() -> Date? {
        return Date(timeIntervalSince1970: TimeInterval(self) / 1000.0)
    }
    
    func toDateString(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> String? {
        guard let date = self.toDate() else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}

extension String {
    func timeStampToDate(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> Date? {
        // If the string can be converted to TimeInterval (Double)
        // then we assume it's a timestamp in milliseconds.
        if let milliseconds = TimeInterval(self) {
            return Date(timeIntervalSince1970: milliseconds/1000.0)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_GB") // set locale to reliable en_GB
            dateFormatter.dateFormat = format
            let date = dateFormatter.date(from: self)
            return date
        }
    }
    
    func toDate(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}

extension Date {
    func toTimestampString() -> String {
        return String(Int64(self.timeIntervalSince1970 * 1000))
    }
    
    func toString(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}

extension Encodable {
    func toData() -> Data! {
        if let encoded = try? JSONEncoder().encode(self) {
            return encoded
        }
        return nil
    }
    
    func toJsonString() -> String {
        if let jsonData = self.toData(), let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return ""
    }
    
    
    func asDictionary() -> [String: Any] {
        guard let data = self.toData() else { return [:] }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}

extension String {
    func timeElapsedSinceDate() -> String? {
        guard let date = self.toDate() else { return nil }
        
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: currentDate)
        
        if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}
