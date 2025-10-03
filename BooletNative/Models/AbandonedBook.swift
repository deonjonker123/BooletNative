import Foundation

struct AbandonedBook: Identifiable, Codable {
    let id: Int
    let bookId: Int
    var pageAtAbandonment: Int?
    var reason: String?
    var startDate: Date?
    var abandonmentDate: Date

    var book: Book?

    var progressPercentage: Double? {
        guard let book = book,
              let pageAtAbandonment = pageAtAbandonment,
              book.pageCount > 0 else { return nil }
        return (Double(pageAtAbandonment) / Double(book.pageCount)) * 100.0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case pageAtAbandonment = "page_at_abandonment"
        case reason
        case startDate = "start_date"
        case abandonmentDate = "abandonment_date"
    }
}
