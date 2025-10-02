//
//  CompletedBooksView.swift
//  Booklet
//
//  View for completed books with ratings and completion dates
//

import SwiftUI

struct CompletedBooksView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var completedBooks: [CompletedBook] = []
    @State private var filteredBooks: [CompletedBook] = []
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .completionDate
    @State private var rowsPerPage: Int = 50
    @State private var currentPage: Int = 0
    @State private var bookToEdit: CompletedBook?
    @State private var bookToRemove: CompletedBook?
    
    enum SortOption: String, CaseIterable {
        case author = "Author"
        case title = "Title"
        case pageCount = "Page Count"
        case completionDate = "Completion Date"
    }
    
    var paginatedBooks: [CompletedBook] {
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
                Text("Completed Books")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
            }
            .padding(20)
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                TextField("Search completed books...", text: $searchText)
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
                    .frame(width: 180, alignment: .leading)
                Text("Series")
                    .frame(width: 130, alignment: .leading)
                Text("Author")
                    .frame(width: 130, alignment: .leading)
                Text("Genre")
                    .frame(width: 100, alignment: .leading)
                Text("Pages")
                    .frame(width: 60, alignment: .leading)
                Text("Rating")
                    .frame(width: 80, alignment: .leading)
                Text("Completed")
                    .frame(width: 100, alignment: .leading)
                Text("Actions")
                    .frame(width: 150, alignment: .leading)
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
                    ForEach(paginatedBooks) { completed in
                        if let book = completed.book {
                            CompletedBookRow(
                                completed: completed,
                                book: book,
                                navigationPath: $navigationPath,
                                onEdit: { bookToEdit = completed },
                                onRemove: { bookToRemove = completed }
                            )
                            Divider()
                        }
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
        .sheet(item: $bookToEdit) { completed in
            EditCompletedBookModal(
                completed: completed,
                onSave: {
                    loadBooks()
                    bookToEdit = nil
                },
                onCancel: {
                    bookToEdit = nil
                }
            )
        }
        .alert("Remove from Completed?", isPresented: Binding(
            get: { bookToRemove != nil },
            set: { if !$0 { bookToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                bookToRemove = nil
            }
            Button("Remove") {
                if let completed = bookToRemove {
                    _ = dbManager.removeFromCompleted(id: completed.id)
                    loadBooks()
                    bookToRemove = nil
                }
            }
        } message: {
            if let completed = bookToRemove, let book = completed.book {
                Text("Remove \"\(book.title)\" from completed books? The book will return to the library and all completion data will be lost.")
            }
        }
        .onAppear {
            loadBooks()
        }
    }
    
    private func loadBooks() {
        completedBooks = dbManager.getAllCompletedBooks()
        filterAndSortBooks()
    }
    
    private func filterAndSortBooks() {
        var filtered = completedBooks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { completed in
                guard let book = completed.book else { return false }
                return book.title.localizedCaseInsensitiveContains(searchText) ||
                       book.author.localizedCaseInsensitiveContains(searchText) ||
                       (book.series?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                       (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .author:
            filtered.sort { ($0.book?.author ?? "") < ($1.book?.author ?? "") }
        case .title:
            filtered.sort { ($0.book?.title ?? "") < ($1.book?.title ?? "") }
        case .pageCount:
            filtered.sort { ($0.book?.pageCount ?? 0) < ($1.book?.pageCount ?? 0) }
        case .completionDate:
            filtered.sort { $0.completionDate > $1.completionDate }
        }
        
        filteredBooks = filtered
        currentPage = 0
    }
}

struct CompletedBookRow: View {
    let completed: CompletedBook
    let book: Book
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
                    .frame(width: 180, alignment: .leading)
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
                        .frame(width: 130, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 130, alignment: .leading)
            }
            
            // Author (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.author(name: book.author))
            }) {
                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .frame(width: 130, alignment: .leading)
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
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
            }
            
            // Page Count
            Text("\(book.pageCount)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Rating
            HStack(spacing: 2) {
                if let rating = completed.rating {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(star <= rating ? .yellow : .gray)
                    }
                } else {
                    Text("-")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .leading)
            
            // Completion Date
            Text(dateFormatter.string(from: completed.completionDate))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
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
                
                Button("Remove") {
                    onRemove()
                }
                .buttonStyle(.borderless)
                .font(.system(size: 12))
                .foregroundColor(.red)
            }
            .frame(width: 150, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct EditCompletedBookModal: View {
    let completed: CompletedBook
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var rating: Int
    @State private var review: String
    @State private var startDate: Date
    @State private var completionDate: Date
    
    init(completed: CompletedBook, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.completed = completed
        self.onSave = onSave
        self.onCancel = onCancel
        _rating = State(initialValue: completed.rating ?? 3)
        _review = State(initialValue: completed.review ?? "")
        _startDate = State(initialValue: completed.startDate ?? completed.completionDate)
        _completionDate = State(initialValue: completed.completionDate)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Completed Book")
                .font(.system(size: 20, weight: .semibold))
            
            if let book = completed.book {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Form {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(.system(size: 14, weight: .medium))
                    
                    TextEditor(text: $review)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.3), width: 1)
                }
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                
                DatePicker("Completion Date", selection: $completionDate, displayedComponents: .date)
            }
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func saveChanges() {
        _ = dbManager.updateCompletedBook(
            id: completed.id,
            rating: rating,
            review: review.isEmpty ? nil : review,
            startDate: startDate,
            completionDate: completionDate
        )
        onSave()
    }
}

#Preview {
    CompletedBooksView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
