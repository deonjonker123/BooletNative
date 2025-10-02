//
//  AbandonedBooksView.swift
//  Booklet
//
//  View for abandoned books with reasons and abandonment details
//

import SwiftUI

struct AbandonedBooksView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var abandonedBooks: [AbandonedBook] = []
    @State private var filteredBooks: [AbandonedBook] = []
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .abandonmentDate
    @State private var rowsPerPage: Int = 50
    @State private var currentPage: Int = 0
    @State private var bookToEdit: AbandonedBook?
    @State private var bookToRemove: AbandonedBook?
    
    enum SortOption: String, CaseIterable {
        case author = "Author"
        case title = "Title"
        case pageCount = "Page Count"
        case abandonmentDate = "Abandonment Date"
    }
    
    var paginatedBooks: [AbandonedBook] {
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
                Text("Abandoned Books")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
            }
            .padding(20)
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                TextField("Search abandoned books...", text: $searchText)
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
                    .frame(width: 160, alignment: .leading)
                Text("Series")
                    .frame(width: 120, alignment: .leading)
                Text("Author")
                    .frame(width: 120, alignment: .leading)
                Text("Genre")
                    .frame(width: 100, alignment: .leading)
                Text("Pages")
                    .frame(width: 60, alignment: .leading)
                Text("Page Stopped")
                    .frame(width: 90, alignment: .leading)
                Text("Abandoned")
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
                    ForEach(paginatedBooks) { abandoned in
                        if let book = abandoned.book {
                            AbandonedBookRow(
                                abandoned: abandoned,
                                book: book,
                                navigationPath: $navigationPath,
                                onEdit: { bookToEdit = abandoned },
                                onRemove: { bookToRemove = abandoned }
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
        .sheet(item: $bookToEdit) { abandoned in
            EditAbandonedBookModal(
                abandoned: abandoned,
                onSave: {
                    loadBooks()
                    bookToEdit = nil
                },
                onCancel: {
                    bookToEdit = nil
                }
            )
        }
        .alert("Remove from Abandoned?", isPresented: Binding(
            get: { bookToRemove != nil },
            set: { if !$0 { bookToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                bookToRemove = nil
            }
            Button("Remove") {
                if let abandoned = bookToRemove {
                    _ = dbManager.removeFromAbandoned(id: abandoned.id)
                    loadBooks()
                    bookToRemove = nil
                }
            }
        } message: {
            if let abandoned = bookToRemove, let book = abandoned.book {
                Text("Remove \"\(book.title)\" from abandoned books? The book will return to the library and all abandonment data will be lost.")
            }
        }
        .onAppear {
            loadBooks()
        }
    }
    
    private func loadBooks() {
        abandonedBooks = dbManager.getAllAbandonedBooks()
        filterAndSortBooks()
    }
    
    private func filterAndSortBooks() {
        var filtered = abandonedBooks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { abandoned in
                guard let book = abandoned.book else { return false }
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
        case .abandonmentDate:
            filtered.sort { $0.abandonmentDate > $1.abandonmentDate }
        }
        
        filteredBooks = filtered
        currentPage = 0
    }
}

struct AbandonedBookRow: View {
    let abandoned: AbandonedBook
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
                    .frame(width: 160, alignment: .leading)
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
            
            // Author (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.author(name: book.author))
            }) {
                Text(book.author)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                    .frame(width: 120, alignment: .leading)
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
            
            // Page at Abandonment
            if let page = abandoned.pageAtAbandonment {
                Text("\(page)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
            } else {
                Text("-")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 90, alignment: .leading)
            }
            
            // Abandonment Date
            Text(dateFormatter.string(from: abandoned.abandonmentDate))
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

struct EditAbandonedBookModal: View {
    let abandoned: AbandonedBook
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var pageAtAbandonment: String
    @State private var reason: String
    @State private var startDate: Date
    @State private var abandonmentDate: Date
    
    init(abandoned: AbandonedBook, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.abandoned = abandoned
        self.onSave = onSave
        self.onCancel = onCancel
        _pageAtAbandonment = State(initialValue: abandoned.pageAtAbandonment != nil ? String(abandoned.pageAtAbandonment!) : "")
        _reason = State(initialValue: abandoned.reason ?? "")
        _startDate = State(initialValue: abandoned.startDate ?? abandoned.abandonmentDate)
        _abandonmentDate = State(initialValue: abandoned.abandonmentDate)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Abandoned Book")
                .font(.system(size: 20, weight: .semibold))
            
            if let book = abandoned.book {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Form {
                TextField("Page at Abandonment", text: $pageAtAbandonment)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason")
                        .font(.system(size: 14, weight: .medium))
                    
                    TextEditor(text: $reason)
                        .frame(height: 100)
                        .border(Color.gray.opacity(0.3), width: 1)
                }
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                
                DatePicker("Abandonment Date", selection: $abandonmentDate, displayedComponents: .date)
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
        let page = Int(pageAtAbandonment)
        
        _ = dbManager.updateAbandonedBook(
            id: abandoned.id,
            pageAtAbandonment: page,
            reason: reason.isEmpty ? nil : reason,
            startDate: startDate,
            abandonmentDate: abandonmentDate
        )
        onSave()
    }
}

#Preview {
    AbandonedBooksView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
