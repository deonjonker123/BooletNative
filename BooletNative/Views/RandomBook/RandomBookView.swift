//
//  RandomBookView.swift
//  Booklet
//
//  Smart random book selector with filters and rules
//

import SwiftUI

struct RandomBookView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var selectedBook: Book?
    @State private var bookLocation: BookLocation = .library
    @State private var filterAuthor: String = ""
    @State private var filterGenre: String = ""
    @State private var filterPageCountMin: String = ""
    @State private var filterPageCountMax: String = ""
    @State private var showConfirmRead: Bool = false
    @State private var showConfirmReroll: Bool = false
    
    enum BookLocation: String {
        case library = "Library"
        case completed = "Completed"
        case abandoned = "Abandoned"
        case tracking = "Tracking"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Random Book Selector")
                    .font(.system(size: 32, weight: .bold))
                
                // Filters
                VStack(alignment: .leading, spacing: 15) {
                    Text("Filters (Optional)")
                        .font(.system(size: 18, weight: .semibold))
                    
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Author")
                                .font(.system(size: 13, weight: .medium))
                            TextField("Any author", text: $filterAuthor)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Genre")
                                .font(.system(size: 13, weight: .medium))
                            TextField("Any genre", text: $filterGenre)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Page Count Min")
                                .font(.system(size: 13, weight: .medium))
                            TextField("0", text: $filterPageCountMin)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Page Count Max")
                                .font(.system(size: 13, weight: .medium))
                            TextField("9999", text: $filterPageCountMax)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                }
                .padding(20)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                
                // Select Button
                Button(action: selectRandomBook) {
                    HStack {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 20))
                        Text("Select Random Book")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(minWidth: 220)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                // Selected Book Display
                if let book = selectedBook {
                    VStack(alignment: .leading, spacing: 20) {
                        Divider()
                        
                        HStack(alignment: .top, spacing: 25) {
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
                                .frame(width: 150, height: 225)
                                .cornerRadius(10)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 150, height: 225)
                                    .cornerRadius(10)
                            }
                            
                            // Book Details
                            VStack(alignment: .leading, spacing: 12) {
                                Button(action: {
                                    navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                                }) {
                                    Text(book.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                
                                if let seriesDisplay = book.seriesDisplay, let series = book.series {
                                    Button(action: {
                                        navigationPath.append(NavigationDestination.series(name: series))
                                    }) {
                                        HStack {
                                            Image(systemName: "books.vertical")
                                            Text(seriesDisplay)
                                                .font(.system(size: 16))
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Button(action: {
                                    navigationPath.append(NavigationDestination.author(name: book.author))
                                }) {
                                    HStack {
                                        Image(systemName: "person")
                                        Text(book.author)
                                            .font(.system(size: 16))
                                    }
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                
                                if let genre = book.genre {
                                    Button(action: {
                                        navigationPath.append(NavigationDestination.genre(name: genre))
                                    }) {
                                        HStack {
                                            Image(systemName: "tag")
                                            Text(genre)
                                                .font(.system(size: 16))
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("\(book.pageCount) pages")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                
                                // Location Badge
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                    Text(bookLocation.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(locationColor.opacity(0.2))
                                        .foregroundColor(locationColor)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 5)
                                
                                // Synopsis
                                if let synopsis = book.synopsis {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Synopsis")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(synopsis)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                            .lineLimit(6)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 15) {
                            Button("Open Details") {
                                navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                            }
                            .buttonStyle(.bordered)
                            
                            if bookLocation == .library {
                                Button("Read This Book") {
                                    showConfirmRead = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                    .padding(25)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding(30)
        }
        .alert("Send to Reading Tracker?", isPresented: $showConfirmRead) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                if let book = selectedBook {
                    _ = dbManager.addToReadingTracker(bookId: book.id)
                    selectedBook = nil
                }
            }
        } message: {
            if let book = selectedBook {
                Text("Send \"\(book.title)\" to reading tracker?")
            }
        }
    }
    
    private var locationColor: Color {
        switch bookLocation {
        case .library: return .blue
        case .completed: return .green
        case .abandoned: return .red
        case .tracking: return .orange
        }
    }
    
    private func selectRandomBook() {
        let allBooks = dbManager.getAllBooks()
        let completedBooks = dbManager.getAllCompletedBooks()
        let trackedBooks = dbManager.getAllTrackedBooks()
        let abandonedBooks = dbManager.getAllAbandonedBooks()
        
        // Get IDs of non-library books
        let completedIds = Set(completedBooks.map { $0.bookId })
        let trackedIds = Set(trackedBooks.map { $0.bookId })
        let abandonedIds = Set(abandonedBooks.map { $0.bookId })
        
        // Only allow books that are in the library (not completed/tracked/abandoned)
        let libraryBooks = allBooks.filter { book in
            !completedIds.contains(book.id) &&
            !trackedIds.contains(book.id) &&
            !abandonedIds.contains(book.id)
        }
        
        // Get last completed book for rules
        let lastCompleted = completedBooks.first
        
        // Apply filters
        var eligibleBooks = libraryBooks.filter { book in
            if !filterAuthor.isEmpty && !book.author.localizedCaseInsensitiveContains(filterAuthor) {
                return false
            }
            
            if !filterGenre.isEmpty, let genre = book.genre, !genre.localizedCaseInsensitiveContains(filterGenre) {
                return false
            }
            
            if let minPages = Int(filterPageCountMin), book.pageCount < minPages {
                return false
            }
            
            if let maxPages = Int(filterPageCountMax), book.pageCount > maxPages {
                return false
            }
            
            // Smart rules based on last completed book
            if let last = lastCompleted, let lastBook = last.book {
                if book.genre == lastBook.genre && book.genre != nil {
                    return false
                }
                if book.author == lastBook.author {
                    return false
                }
                if book.series == lastBook.series && book.series != nil {
                    return false
                }
                if lastBook.pageCount > 800 && book.pageCount >= 600 {
                    return false
                }
            }
            
            // Series progression rule
            if let series = book.series, let seriesNumber = book.seriesNumber, seriesNumber > 1 {
                let previousNumber = seriesNumber - 1
                let previousCompleted = completedBooks.contains { completed in
                    completed.book?.series == series && completed.book?.seriesNumber == previousNumber
                }
                let lastCompletedIsSameSeries = lastCompleted?.book?.series == series
                if !previousCompleted && !lastCompletedIsSameSeries {
                    return false
                }
            }
            
            return true
        }
        
        // Select random book
        if let randomBook = eligibleBooks.randomElement() {
            selectedBook = randomBook
            bookLocation = .library // Always library since we filtered others out
        } else {
            selectedBook = nil
        }
    }

}

#Preview {
    RandomBookView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
