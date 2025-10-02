//
//  DashboardView.swift
//  Booklet
//
//  Dashboard showing library statistics and current reading
//

import SwiftUI

struct DashboardView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var libraryCount: Int = 0
    @State private var completedCount: Int = 0
    @State private var abandonedCount: Int = 0
    @State private var currentlyReading: [ReadingTrackerEntry] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Dashboard")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 20)
                
                // Stats Grid
                HStack(spacing: 20) {
                    StatCard(title: "Books in Library", value: "\(libraryCount)", color: .blue)
                    StatCard(title: "Completed Books", value: "\(completedCount)", color: .green)
                    StatCard(title: "Abandoned Books", value: "\(abandonedCount)", color: .red)
                }
                
                // Currently Reading Section
                if !currentlyReading.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Currently Reading")
                            .font(.system(size: 24, weight: .semibold))
                        
                        ForEach(currentlyReading) { entry in
                            if let book = entry.book {
                                CurrentlyReadingCard(entry: entry, book: book, navigationPath: $navigationPath)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        libraryCount = dbManager.getAllBooks().count
        completedCount = dbManager.getAllCompletedBooks().count
        abandonedCount = dbManager.getAllAbandonedBooks().count
        currentlyReading = dbManager.getAllTrackedBooks()
    }
}

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

struct CurrentlyReadingCard: View {
    let entry: ReadingTrackerEntry
    let book: Book
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        HStack(spacing: 15) {
            // Cover
            if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 90)
                .cornerRadius(6)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 90)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Button(action: {
                    navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                }) {
                    Text(book.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Text(book.author)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // Progress
                HStack {
                    Text("\(entry.currentPage) / \(book.pageCount) pages")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("(\(Int(entry.progressPercentage))%)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (entry.progressPercentage / 100.0), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            
            Spacer()
        }
        .padding(15)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

#Preview {
    DashboardView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
