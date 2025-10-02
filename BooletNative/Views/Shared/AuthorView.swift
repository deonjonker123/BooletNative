//
//  AuthorView.swift
//  Booklet
//
//  Filtered view showing all books by a specific author
//

import SwiftUI

struct AuthorView: View {
    let authorName: String
    @Binding var navigationPath: NavigationPath
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var books: [BookWithLocation] = []
    @State private var filteredBooks: [BookWithLocation] = []
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .dateAdded
    @State private var rowsPerPage: Int = 50
    @State private var currentPage: Int = 0
    @State private var bookToEdit: Book?
    @State private var bookToDelete: Book?
    @State private var bookToRead: Book?
    
    @Environment(\.dismiss) var dismiss
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case pageCount = "Page Count"
        case dateAdded = "Date Added"
    }
    
    var paginatedBooks: [BookWithLocation] {
        let start = currentPage * rowsPerPage
        let end = min(start + rowsPerPage, filteredBooks.count)
        guard start < filteredBooks.count else { return [] }
        return Array(filteredBooks[start..<end])
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(filteredBooks.count) / Double(rowsPerPage))))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Author")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(authorName)
                        .font(.system(size: 24, weight: .bold))
                }
            }
            .padding(20)
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                TextField("Search books by \(authorName)...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .onChange(of: searchText) { _, _ in
                        filterAndSortBooks()
                    }
                
                Spacer()
                
                Text("Sort by:")
                    .font(.system(size: 13))
                
                Picker("", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                .onChange(of: sortOption) { _, _ in
                    filterAndSortBooks()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            
            Divider()
            
            // Table Header
            HStack(spacing: 10) {
                Text("Cover")
                    .frame(width: 60, alignment: .leading)
                Text("Title")
                    .frame(width: 200, alignment: .leading)
                Text("Series")
                    .frame(width: 150, alignment: .leading)
                Text("Genre")
                    .frame(width: 120, alignment: .leading)
                Text("Pages")
                    .frame(width: 60, alignment: .leading)
                Text("Location")
                    .frame(width: 120, alignment: .leading)
                Text("Actions")
                    .frame(width: 280, alignment: .leading)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(paginatedBooks, id: \.book.id) { item in
                        AuthorBookRow(
                            bookWithLocation: item,
                            navigationPath: $navigationPath,
                            onEdit: { bookToEdit = item.book },
                            onRead: { bookToRead = item.book },
                            onDelete: { bookToDelete = item.book }
                        )
                        Divider()
                    }
                }
            }
            
            Divider()
            
            // Pagination Controls
            HStack {
                Text("\(filteredBooks.count) books")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 10) {
                    Text("Rows per page:")
                        .font(.system(size: 13))
                    
                    Picker("", selection: $rowsPerPage) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                    .onChange(of: rowsPerPage) { _, _ in
                        currentPage = 0
                    }
                    
                    Button(action: { currentPage = max(0, currentPage - 1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage == 0)
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.system(size: 13))
                        .frame(width: 100)
                    
                    Button(action: { currentPage = min(totalPages - 1, currentPage + 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
            }
            .padding(15)
        }
        .sheet(item: $bookToEdit) { book in
            EditBookModal(book: book, onSave: {
                loadBooks()
                bookToEdit = nil
            }, onCancel: {
                bookToEdit = nil
            })
        }
        .alert("Send to Reading Tracker?", isPresented: Binding(
            get: { bookToRead != nil },
            set: { if !$0 { bookToRead = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                bookToRead = nil
            }
            Button("Confirm") {
                if let book = bookToRead {
                    _ = dbManager.addToReadingTracker(bookId: book.id)
                    loadBooks()
                    bookToRead = nil
                }
            }
        } message: {
            if let book = bookToRead {
                Text("Send \"\(book.title)\" to reading tracker?")
            }
        }
        .alert("Delete Book?", isPresented: Binding(
            get: { bookToDelete != nil },
            set: { if !$0 { bookToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                bookToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let book = bookToDelete {
                    _ = dbManager.deleteBook(id: book.id)
                    loadBooks()
                    bookToDelete = nil
                }
            }
        } message: {
            if let book = bookToDelete {
                Text("Are you sure you want to delete \"\(book.title)\"? This action cannot be undone.")
            }
        }
        .onAppear {
            loadBooks()
        }
    }
    
    private func loadBooks() {
        let allBooks = dbManager.getAllBooks().filter { $0.author == authorName }
        let tracked = dbManager.getAllTrackedBooks()
        let completed = dbManager.getAllCompletedBooks()
        let abandoned = dbManager.getAllAbandonedBooks()
        
        books = allBooks.map { book in
            var location: BookLocation = .library
            
            if tracked.contains(where: { $0.bookId == book.id }) {
                location = .tracking
            } else if completed.contains(where: { $0.bookId == book.id }) {
                location = .completed
            } else if abandoned.contains(where: { $0.bookId == book.id }) {
                location = .abandoned
            }
            
            return BookWithLocation(book: book, location: location)
        }
        
        filterAndSortBooks()
    }
    
    private func filterAndSortBooks() {
        var filtered = books
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.book.title.localizedCaseInsensitiveContains(searchText) ||
                (item.book.series?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.book.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .title:
            filtered.sort { $0.book.title < $1.book.title }
        case .pageCount:
            filtered.sort { $0.book.pageCount < $1.book.pageCount }
        case .dateAdded:
            filtered.sort { $0.book.dateAdded > $1.book.dateAdded }
        }
        
        filteredBooks = filtered
        currentPage = 0
    }
}

struct AuthorBookRow: View {
    let bookWithLocation: BookWithLocation
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRead: () -> Void
    let onDelete: () -> Void
    
    var book: Book {
        bookWithLocation.book
    }
    
    var location: BookLocation {
        bookWithLocation.location
    }
    
    var body: some View {
        HStack(spacing: 10) {
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
                .frame(width: 40, height: 60)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 60)
                    .cornerRadius(4)
            }
            
            // Title (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
            }) {
                Text(book.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .frame(width: 200, alignment: .leading)
                    .lineLimit(2)
            }
            .buttonStyle(.plain)
            
            // Series (clickable)
            if let series = book.series {
                Button(action: {
                    navigationPath.append(NavigationDestination.series(name: series))
                }) {
                    Text(book.seriesDisplay ?? series)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .frame(width: 150, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
            }
            
            // Genre (clickable)
            if let genre = book.genre {
                Button(action: {
                    navigationPath.append(NavigationDestination.genre(name: genre))
                }) {
                    Text(genre)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .frame(width: 120, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)
            }
            
            // Page Count
            Text("\(book.pageCount)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Location Badge
            Text(location.displayName)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(location.color.opacity(0.2))
                .foregroundColor(location.color)
                .cornerRadius(6)
                .frame(width: 120, alignment: .leading)
            
            // Actions
            HStack(spacing: 8) {
                Button("Open") {
                    navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                
                if location == .library {
                    Button("Read") {
                        onRead()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                }
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                .foregroundColor(.red)
            }
            .frame(width: 280, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct BookWithLocation {
    let book: Book
    let location: BookLocation
}

enum BookLocation {
    case library
    case completed
    case abandoned
    case tracking
    
    var displayName: String {
        switch self {
        case .library: return "Library"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        case .tracking: return "Tracking"
        }
    }
    
    var color: Color {
        switch self {
        case .library: return .blue
        case .completed: return .green
        case .abandoned: return .red
        case .tracking: return .orange
        }
    }
}

#Preview {
    AuthorView(authorName: "J.K. Rowling", navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
