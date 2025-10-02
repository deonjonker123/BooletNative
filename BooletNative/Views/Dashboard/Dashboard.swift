//
//  DashboardView.swift
//  Booklet
//
//  Modern, compact dashboard with enhanced visuals
//

import SwiftUI

struct DashboardView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var libraryCount: Int = 0
    @State private var completedCount: Int = 0
    @State private var abandonedCount: Int = 0
    @State private var currentlyReading: [ReadingTrackerEntry] = []
    
    // For animation
    @State private var isLoaded: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with gradient text
                Text("Dashboard")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)
                
                Divider()
                    .padding(.bottom, 32)
                
                VStack(alignment: .leading, spacing: 40) {
                    // Stats Grid - Clickable Cards
                    HStack(spacing: 20) {
                    ModernStatCard(
                        title: "In Library",
                        value: "\(libraryCount)",
                        icon: "books.vertical.fill",
                        gradient: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        delay: 0.0
                    )
                    .onTapGesture {
                        navigationPath.append(
                                NavigationDestination.allBooks
                            )
                    }
                    
                    ModernStatCard(
                        title: "Completed",
                        value: "\(completedCount)",
                        icon: "checkmark.seal.fill",
                        gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                        delay: 0.1
                    )
                    .onTapGesture {
                        navigationPath.append(
                                NavigationDestination.completedBooks
                            )
                    }
                    
                    ModernStatCard(
                        title: "Abandoned",
                        value: "\(abandonedCount)",
                        icon: "xmark.circle.fill",
                        gradient: [Color(hex: "eb3349"), Color(hex: "f45c43")],
                        delay: 0.2
                    )
                    .onTapGesture {
                        navigationPath.append(
                                NavigationDestination.abandonedBooks
                            )
                    }
                }
                .padding(.horizontal, 32)
                
                // Currently Reading Section
                if !currentlyReading.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Currently Reading", systemImage: "book.fill")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(currentlyReading.count) book\(currentlyReading.count == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 32)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(currentlyReading.enumerated()), id: \.element.id) { index, entry in
                                    if let book = entry.book {
                                        ModernReadingCard(
                                            entry: entry,
                                            book: book,
                                            delay: Double(index) * 0.1
                                        )
                                        .onTapGesture {
                                            navigationPath.append(NavigationDestination.readingTracker)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("No books in progress")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Text("Start tracking a book from your library")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 32)
                }
                
                    Spacer(minLength: 32)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear {
            loadData()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isLoaded = true
            }
        }
    }
    
    private func loadData() {
        // Get all books
        let allBooks = dbManager.getAllBooks()
        
        // Get books that are in other locations
        let trackedBookIds = Set(dbManager.getAllTrackedBooks().map { $0.bookId })
        let completedBookIds = Set(dbManager.getAllCompletedBooks().map { $0.bookId })
        let abandonedBookIds = Set(dbManager.getAllAbandonedBooks().map { $0.bookId })
        
        // FIXED: Only count books that are NOT in tracker, completed, or abandoned
        libraryCount = allBooks.filter { book in
            !trackedBookIds.contains(book.id) &&
            !completedBookIds.contains(book.id) &&
            !abandonedBookIds.contains(book.id)
        }.count
        
        completedCount = dbManager.getAllCompletedBooks().count
        abandonedCount = dbManager.getAllAbandonedBooks().count
        currentlyReading = dbManager.getAllTrackedBooks()
    }
}

// MARK: - Modern Stat Card

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    let delay: Double
    
    @State private var isVisible: Bool = false
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
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
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 12 : 8, x: 0, y: isHovered ? 6 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isHovered ? gradient.map { $0.opacity(0.3) } : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Modern Reading Card

struct ModernReadingCard: View {
    let entry: ReadingTrackerEntry
    let book: Book
    let delay: Double
    
    @State private var isVisible: Bool = false
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover with shadow
            Group {
                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "667eea").opacity(0.3), Color(hex: "764ba2").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "667eea").opacity(0.3), Color(hex: "764ba2").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .frame(width: 70, height: 105)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: 180, alignment: .leading)
                
                Text(book.author)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Compact progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("\(Int(entry.progressPercentage))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("• \(entry.currentPage) / \(book.pageCount)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (entry.progressPercentage / 100.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 10 : 6, x: 0, y: isHovered ? 4 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.secondary.opacity(isHovered ? 0.2 : 0.1), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Old StatCard (for Statistics view compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
