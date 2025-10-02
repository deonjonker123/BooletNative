//
//  Book.swift
//  Booklet
//
//  Model representing a book in the library
//

import Foundation

struct Book: Identifiable, Codable {
    let id: Int
    var coverUrl: String?
    var title: String
    var series: String?
    var seriesNumber: Double?
    var author: String
    var pageCount: Int
    var synopsis: String?
    var genre: String?
    var dateAdded: Date
    
    // Computed property for display
    var seriesDisplay: String? {
        guard let series = series else { return nil }
        if let number = seriesNumber {
            return "\(series) #\(formatSeriesNumber(number))"
        }
        return series
    }
    
    // Format series number (remove .0 for whole numbers)
    private func formatSeriesNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(number))
        }
        return String(number)
    }
    
    // Database column mapping
    enum CodingKeys: String, CodingKey {
        case id
        case coverUrl = "cover_url"
        case title
        case series
        case seriesNumber = "series_number"
        case author
        case pageCount = "page_count"
        case synopsis
        case genre
        case dateAdded = "date_added"
    }
}
