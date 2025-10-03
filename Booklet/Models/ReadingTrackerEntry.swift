import Foundation

struct ReadingTrackerEntry: Identifiable, Codable {
    let id: Int
    let bookId: Int
    var currentPage: Int
    var startDate: Date

    var book: Book?

    var progressPercentage: Double {
        guard let book = book, book.pageCount > 0 else { return 0.0 }
        return (Double(currentPage) / Double(book.pageCount)) * 100.0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case currentPage = "current_page"
        case startDate = "start_date"
    }
}
