//
//  DateExtension.swift
//  swiftMessanger
//
//  Created by Furkan Alioglu on 7.08.2023.
//

import Foundation


extension String {
    func toDate(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        return date
    }
}

extension Date {
    func toString(withFormat format: String = "dd-MM-yyyy, HH:mm:ss") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_GB")
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
