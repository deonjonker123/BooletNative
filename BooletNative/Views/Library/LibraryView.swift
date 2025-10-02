//
//  LibraryView.swift
//  Booklet
//
//  Library page with all books in table layout
//

import SwiftUI

struct LibraryView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var books: [Book] = []
    @State private var filteredBooks: [Book] = []
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .dateAdded
    @State private var rowsPerPage: Int = 50
    @State private var currentPage: Int = 0
    @State private var showAddBookModal: Bool = false
    @State private var bookToEdit: Book?
    @State private var bookToDelete: Book?
    @State private var bookToRead: Book?
    
    enum SortOption: String, CaseIterable {
        case author = "Author"
        case title = "Title"
        case pageCount = "Page Count"
        case dateAdded = "Date Added"
    }
    
    var paginatedBooks: [Book] {
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
                Text("Library")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
                
                Button("Add Book") {
                    showAddBookModal = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                TextField("Search library...", text: $searchText)
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
                Text("Author")
                    .frame(width: 150, alignment: .leading)
                Text("Genre")
                    .frame(width: 120, alignment: .leading)
                Text("Pages")
                    .frame(width: 60, alignment: .leading)
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
                    ForEach(paginatedBooks) { book in
                        BookRow(
                            book: book,
                            navigationPath: $navigationPath,
                            onEdit: { bookToEdit = book },
                            onRead: { bookToRead = book },
                            onDelete: { bookToDelete = book }
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
        .sheet(isPresented: $showAddBookModal) {
            AddBookModal(isPresented: $showAddBookModal, onSave: {
                loadBooks()
            })
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
        // Get all books
        let allBooks = dbManager.getAllBooks()
        
        // Get books that are in other locations
        let trackedBookIds = Set(dbManager.getAllTrackedBooks().map { $0.bookId })
        let completedBookIds = Set(dbManager.getAllCompletedBooks().map { $0.bookId })
        let abandonedBookIds = Set(dbManager.getAllAbandonedBooks().map { $0.bookId })
        
        // Filter to only books that are NOT in tracker, completed, or abandoned
        books = allBooks.filter { book in
            !trackedBookIds.contains(book.id) &&
            !completedBookIds.contains(book.id) &&
            !abandonedBookIds.contains(book.id)
        }
        
        filterAndSortBooks()
    }
    
    private func filterAndSortBooks() {
        var filtered = books
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                (book.series?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .author:
            filtered.sort { $0.author < $1.author }
        case .title:
            filtered.sort { $0.title < $1.title }
        case .pageCount:
            filtered.sort { $0.pageCount < $1.pageCount }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        filteredBooks = filtered
        currentPage = 0
    }
}

struct BookRow: View {
    let book: Book
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRead: () -> Void
    let onDelete: () -> Void
    
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
            
            // Author (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.author(name: book.author))
            }) {
                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .frame(width: 150, alignment: .leading)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            
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
                
                Button("Read") {
                    onRead()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                
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

struct EditBookModal: View {
    let book: Book
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var coverUrl: String
    @State private var title: String
    @State private var series: String
    @State private var seriesNumber: String
    @State private var author: String
    @State private var pageCount: String
    @State private var synopsis: String
    @State private var genre: String
    
    init(book: Book, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.book = book
        self.onSave = onSave
        self.onCancel = onCancel
        _coverUrl = State(initialValue: book.coverUrl ?? "")
        _title = State(initialValue: book.title)
        _series = State(initialValue: book.series ?? "")
        _seriesNumber = State(initialValue: book.seriesNumber != nil ? String(book.seriesNumber!) : "")
        _author = State(initialValue: book.author)
        _pageCount = State(initialValue: String(book.pageCount))
        _synopsis = State(initialValue: book.synopsis ?? "")
        _genre = State(initialValue: book.genre ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Book")
                .font(.system(size: 20, weight: .semibold))
            
            Form {
                TextField("Cover URL", text: $coverUrl)
                TextField("Title", text: $title)
                TextField("Series", text: $series)
                TextField("Series Number", text: $seriesNumber)
                TextField("Author", text: $author)
                TextField("Page Count", text: $pageCount)
                TextField("Genre", text: $genre)
                TextField("Synopsis", text: $synopsis, axis: .vertical)
                    .lineLimit(4...8)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveBook()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func saveBook() {
        guard let pages = Int(pageCount) else { return }
        
        let seriesNum = Double(seriesNumber)
        
        _ = dbManager.updateBook(
            id: book.id,
            coverUrl: coverUrl.isEmpty ? nil : coverUrl,
            title: title,
            series: series.isEmpty ? nil : series,
            seriesNumber: seriesNum,
            author: author,
            pageCount: pages,
            synopsis: synopsis.isEmpty ? nil : synopsis,
            genre: genre.isEmpty ? nil : genre
        )
        
        onSave()
    }
}

#Preview {
    LibraryView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
