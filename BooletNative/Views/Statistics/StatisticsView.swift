//
//  StatisticsView.swift
//  Booklet
//
//  Statistics page with modern charts and reading metrics
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
            VStack(alignment: .leading, spacing: 32) {
                // Header with Year Filter
                HStack {
                    Text("Statistics")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 14, design: .rounded))
                        .frame(width: 140)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: selectedYear) { _, _ in
                        filterBooks()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal, 32)
                
                // Reading Streak
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Reading Streak")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(readingStreak)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("consecutive days")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 32)
                
                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatsStatCard(
                        title: "Completed",
                        value: "\(totalCompleted)",
                        icon: "checkmark.seal.fill",
                        gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")]
                    )
                    
                    StatsStatCard(
                        title: "Pages Read",
                        value: "\(totalPagesRead)",
                        icon: "book.pages.fill",
                        gradient: [Color(hex: "667eea"), Color(hex: "764ba2")]
                    )
                    
                    StatsStatCard(
                        title: "Abandoned",
                        value: "\(totalAbandoned)",
                        icon: "xmark.circle.fill",
                        gradient: [Color(hex: "eb3349"), Color(hex: "f45c43")]
                    )
                    
                    if let avgDays = averageTimeToFinish {
                        StatsStatCard(
                            title: "Avg. Days",
                            value: String(format: "%.0f", avgDays),
                            icon: "clock.fill",
                            gradient: [Color(hex: "f093fb"), Color(hex: "f5576c")]
                        )
                    } else {
                        StatsStatCard(
                            title: "Avg. Days",
                            value: "—",
                            icon: "clock.fill",
                            gradient: [Color(hex: "f093fb"), Color(hex: "f5576c")]
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                // Charts Section
                VStack(spacing: 24) {
                    // Reading Activity Over Time
                    if !filteredBooks.isEmpty {
                        ChartCard(title: "Reading Activity", icon: "chart.bar.fill") {
                            Chart {
                                ForEach(monthlyStats, id: \.month) { stat in
                                    BarMark(
                                        x: .value("Month", stat.monthName),
                                        y: .value("Books", stat.booksCount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 250)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    
                    // Top Authors
                    if !topAuthors.isEmpty {
                        ChartCard(title: "Top 10 Authors", icon: "person.3.fill") {
                            Chart {
                                ForEach(topAuthors, id: \.author) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Author", item.author)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 400)
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                        }
                    }
                    
                    // Top Genres
                    if !topGenres.isEmpty {
                        ChartCard(title: "Top 10 Genres", icon: "tag.fill") {
                            Chart {
                                ForEach(topGenres, id: \.genre) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Genre", item.genre)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 400)
                            .chartXAxis {
                                AxisMarks(position: .bottom)
                            }
                        }
                    }
                    
                    // Rating Distribution
                    if !ratingSplit.isEmpty {
                        ChartCard(title: "Rating Distribution", icon: "star.fill") {
                            Chart {
                                ForEach(ratingSplit, id: \.rating) { item in
                                    BarMark(
                                        x: .value("Rating", "\(item.rating) ⭐"),
                                        y: .value("Count", item.count)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.yellow.opacity(0.8), Color.orange],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(6)
                                }
                            }
                            .frame(height: 250)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
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

// MARK: - Stats Stat Card

struct StatsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient.map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Chart Card

struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
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
