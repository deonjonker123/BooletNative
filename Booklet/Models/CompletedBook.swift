import Foundation

struct CompletedBook: Identifiable, Codable {
    let id: Int
    let bookId: Int
    var rating: Int?
    var review: String?
    var startDate: Date?
    var completionDate: Date

    var book: Book?

    var daysToComplete: Int? {
        guard let startDate = startDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: completionDate)
        return components.day
    }

    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case rating
        case review
        case startDate = "start_date"
        case completionDate = "completion_date"
    }
}
