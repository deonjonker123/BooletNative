//
//  MainView.swift
//  Booklet
//
//  Main navigation container with modern sidebar
//

import SwiftUI

// Navigation destination enum
enum NavigationDestination: Hashable {
    case bookDetail(bookId: Int)
    case author(name: String)
    case series(name: String)
    case genre(name: String)
    case filteredCompleted(filterType: CompletedBooksFilterType, filterValue: String, timePeriod: String)
    case abandonedBooks
    case allBooks
    case completedBooks
}

struct MainView: View {
    @StateObject private var dbManager = DatabaseManager.shared
    @State private var selectedView: NavigationItem = .dashboard
    @State private var navigationPath = NavigationPath()
    
    enum NavigationItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case library = "Library"
        case readingTracker = "Reading Tracker"
        case completedBooks = "Completed Books"
        case abandonedBooks = "Abandoned Books"
        case statistics = "Statistics"
        case randomBook = "Random Book"
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .library: return "books.vertical.fill"
            case .readingTracker: return "book.fill"
            case .completedBooks: return "checkmark.circle.fill"
            case .abandonedBooks: return "xmark.circle.fill"
            case .statistics: return "chart.bar.fill"
            case .randomBook: return "dice.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .dashboard: return [Color(hex: "667eea"), Color(hex: "764ba2")]
            case .library: return [Color(hex: "667eea"), Color(hex: "764ba2")]
            case .readingTracker: return [Color(hex: "f093fb"), Color(hex: "f5576c")]
            case .completedBooks: return [Color(hex: "11998e"), Color(hex: "38ef7d")]
            case .abandonedBooks: return [Color(hex: "eb3349"), Color(hex: "f45c43")]
            case .statistics: return [Color(hex: "667eea"), Color(hex: "764ba2")]
            case .randomBook: return [Color(hex: "a8edea"), Color(hex: "fed6e3")]
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Modern Sidebar
            VStack(spacing: 0) {
                // App Title Header
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        Text("Booklet")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                }
                
                Divider()
                    .padding(.vertical, 12)
                
                // Navigation Items
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(NavigationItem.allCases, id: \.self) { item in
                            ModernNavItem(
                                item: item,
                                isSelected: selectedView == item,
                                action: {
                                    selectedView = item
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
                
                Spacer()
            }
            .frame(minWidth: 240)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        } detail: {
            NavigationStack(path: $navigationPath) {
                // Main content area
                Group {
                    switch selectedView {
                    case .dashboard:
                        DashboardView(navigationPath: $navigationPath)
                    case .library:
                        LibraryView(navigationPath: $navigationPath)
                    case .readingTracker:
                        ReadingTrackerView(navigationPath: $navigationPath)
                    case .completedBooks:
                        CompletedBooksView(navigationPath: $navigationPath)
                    case .abandonedBooks:
                        AbandonedBooksView(navigationPath: $navigationPath)
                    case .statistics:
                        StatisticsView(navigationPath: $navigationPath)
                    case .randomBook:
                        RandomBookView(navigationPath: $navigationPath)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .bookDetail(let bookId):
                        BookDetailView(bookId: bookId, navigationPath: $navigationPath)
                    case .author(let name):
                        AuthorView(authorName: name, navigationPath: $navigationPath)
                    case .series(let name):
                        SeriesView(seriesName: name, navigationPath: $navigationPath)
                    case .genre(let name):
                        GenreView(genreName: name, navigationPath: $navigationPath)
                    case .filteredCompleted(let filterType, let filterValue, let timePeriod):
                        FilteredCompletedBooksView(
                            filterType: filterType,
                            filterValue: filterValue,
                            timePeriod: timePeriod,
                            navigationPath: $navigationPath
                        )
                    case .abandonedBooks:
                        AbandonedBooksView(navigationPath: $navigationPath)
                    case .allBooks:
                        LibraryView(navigationPath: $navigationPath)
                    case .completedBooks:
                        CompletedBooksView(navigationPath: $navigationPath)
                    }
                }
            }
        }
        .environmentObject(dbManager)
    }
}

// MARK: - Modern Nav Item

struct ModernNavItem: View {
    let item: MainView.NavigationItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with gradient background
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: item.gradient.map { $0.opacity(0.2) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                    }
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(
                            isSelected || isHovered ?
                            LinearGradient(
                                colors: item.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.secondary, .secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                }
                
                // Label
                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                // Selected indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: item.gradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 20)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isSelected ?
                        Color(nsColor: .controlBackgroundColor) :
                        (isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ?
                        LinearGradient(
                            colors: item.gradient.map { $0.opacity(0.3) },
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MainView()
}
