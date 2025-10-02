//
//  MainView.swift
//  Booklet
//
//  Main navigation container with sidebar
//

import SwiftUI

// Navigation destination enum
enum NavigationDestination: Hashable {
    case bookDetail(bookId: Int)
    case author(name: String)
    case series(name: String)
    case genre(name: String)
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
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(NavigationItem.allCases, id: \.self, selection: $selectedView) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Booklet")
            .frame(minWidth: 200)
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
                    }
                }
            }
        }
        .environmentObject(dbManager)
    }
}

#Preview {
    MainView()
}
