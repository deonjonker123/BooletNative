//
//  StatisticsView.swift
//  Booklet
//
//  Statistics page with charts and reading metrics
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var selectedYear: String = "All Time"
    @State private var completedBooks: [CompletedBook] = []
    @State private var filteredBooks: [CompletedBook] = []
    @State private var readingStreak: Int = 0
    
    var availableYears: [String] {
        let years = Set(completedBooks.compactMap { Calendar.current.component(.year, from: $0.completionDate) })
        return ["All Time"] + years.sorted(by: >).map { String($0) }
    }
    
    var totalCompleted: Int {
        filteredBooks.count
    }
    
    var totalPagesRead: Int {
        filteredBooks.compactMap { $0.book?.pageCount }.reduce(0, +)
    }
    
    var totalAbandoned: Int {
        let abandoned = dbManager.getAllAbandonedBooks()
        if selectedYear == "All Time" {
            return abandoned.count
        } else if let year = Int(selectedYear) {
            return abandoned.filter { Calendar.current.component(.year, from: $0.abandonmentDate) == year }.count
        }
        return 0
    }
    
    var averageTimeToFinish: Double? {
        let booksWithDates = filteredBooks.filter { $0.startDate != nil && $0.daysToComplete != nil }
        guard !booksWithDates.isEmpty else { return nil }
        let totalDays = booksWithDates.compactMap { $0.daysToComplete }.reduce(0, +)
        return Double(totalDays) / Double(booksWithDates.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header with Year Filter
                HStack {
                    Text("Statistics")
                        .font(.system(size: 32, weight: .bold))
                    
                    Spacer()
                    
                    Picker("", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                    .onChange(of: selectedYear) { _, _ in
                        filterBooks()
                    }
                }
                
                // Reading Streak
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading Streak")
                        .font(.system(size: 20, weight: .semibold))
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("\(readingStreak)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("consecutive days")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Raw Numbers Grid
                HStack(spacing: 20) {
                    StatCard(
                        title: "Completed Books",
                        value: "\(totalCompleted)",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Pages Read",
                        value: "\(totalPagesRead)",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Abandoned Books",
                        value: "\(totalAbandoned)",
                        color: .red
                    )
                    
                    if let avgDays = averageTimeToFinish {
                        StatCard(
                            title: "Avg. Time to Finish",
                            value: String(format: "%.1f days", avgDays),
                            color: .purple
                        )
                    }
                }
                
                // Pages/Books Read Over Time
                if !filteredBooks.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Reading Activity Over Time")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Chart {
                            ForEach(monthlyStats, id: \.month) { stat in
                                BarMark(
                                    x: .value("Month", stat.monthName),
                                    y: .value("Books", stat.booksCount)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .frame(height: 250)
                        .padding(15)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                
                // Top 10 Authors
                if !topAuthors.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Top 10 Most Read Authors")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Chart {
                            ForEach(topAuthors, id: \.author) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Author", item.author)
                                )
                                .foregroundStyle(.green)
                            }
                        }
                        .frame(height: 350)
                        .padding(15)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                
                // Top 10 Genres
                if !topGenres.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Top 10 Most Read Genres")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Chart {
                            ForEach(topGenres, id: \.genre) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Genre", item.genre)
                                )
                                .foregroundStyle(.orange)
                            }
                        }
                        .frame(height: 350)
                        .padding(15)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                
                // Rating Split
                if !ratingSplit.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Rating Distribution")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Chart {
                            ForEach(ratingSplit, id: \.rating) { item in
                                BarMark(
                                    x: .value("Rating", "\(item.rating) ⭐"),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(.yellow)
                            }
                        }
                        .frame(height: 250)
                        .padding(15)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(30)
        }
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        completedBooks = dbManager.getAllCompletedBooks()
        filterBooks()
        calculateReadingStreak()
    }
    
    private func filterBooks() {
        if selectedYear == "All Time" {
            filteredBooks = completedBooks
        } else if let year = Int(selectedYear) {
            filteredBooks = completedBooks.filter {
                Calendar.current.component(.year, from: $0.completionDate) == year
            }
        }
    }
    
    private func calculateReadingStreak() {
        // Get all completion dates sorted descending
        let dates = completedBooks.map { $0.completionDate }.sorted(by: >)
        guard !dates.isEmpty else {
            readingStreak = 0
            return
        }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for completionDate in dates {
            let dateOnly = calendar.startOfDay(for: completionDate)
            let daysDiff = calendar.dateComponents([.day], from: dateOnly, to: currentDate).day ?? 0
            
            if daysDiff == 0 || daysDiff == 1 {
                streak += 1
                currentDate = dateOnly
            } else {
                break
            }
        }
        
        readingStreak = streak
    }
    
    // MARK: - Computed Stats
    
    private var monthlyStats: [MonthlyStats] {
        let calendar = Calendar.current
        var monthData: [Int: (books: Int, pages: Int)] = [:]
        
        for completed in filteredBooks {
            let month = calendar.component(.month, from: completed.completionDate)
            let pages = completed.book?.pageCount ?? 0
            
            if monthData[month] != nil {
                monthData[month]!.books += 1
                monthData[month]!.pages += pages
            } else {
                monthData[month] = (1, pages)
            }
        }
        
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        return (1...12).map { month in
            MonthlyStats(
                month: month,
                monthName: monthNames[month - 1],
                booksCount: monthData[month]?.books ?? 0,
                pagesCount: monthData[month]?.pages ?? 0
            )
        }
    }
    
    private var topAuthors: [AuthorStats] {
        var authorCounts: [String: Int] = [:]
        
        for completed in filteredBooks {
            if let author = completed.book?.author {
                authorCounts[author, default: 0] += 1
            }
        }
        
        return authorCounts
            .map { AuthorStats(author: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .reversed()
            .map { $0 }
    }
    
    private var topGenres: [GenreStats] {
        var genreCounts: [String: Int] = [:]
        
        for completed in filteredBooks {
            if let genre = completed.book?.genre {
                genreCounts[genre, default: 0] += 1
            }
        }
        
        return genreCounts
            .map { GenreStats(genre: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .reversed()
            .map { $0 }
    }
    
    private var ratingSplit: [RatingStats] {
        var ratingCounts: [Int: Int] = [:]
        
        for completed in filteredBooks {
            if let rating = completed.rating {
                ratingCounts[rating, default: 0] += 1
            }
        }
        
        return (1...5).map { rating in
            RatingStats(rating: rating, count: ratingCounts[rating] ?? 0)
        }
    }
}

// MARK: - Supporting Types

struct MonthlyStats {
    let month: Int
    let monthName: String
    let booksCount: Int
    let pagesCount: Int
}

struct AuthorStats {
    let author: String
    let count: Int
}

struct GenreStats {
    let genre: String
    let count: Int
}

struct RatingStats {
    let rating: Int
    let count: Int
}

#Preview {
    StatisticsView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
