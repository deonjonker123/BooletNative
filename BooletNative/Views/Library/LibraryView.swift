//
//  LibraryView.swift
//  Booklet
//
//  Modern library view with enhanced visuals
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
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                Button(action: { showAddBookModal = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Book")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Divider()
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                // Search bar - full width
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search library...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .rounded))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: searchText) { _, _ in
                    filterAndSortBooks()
                }
                
                // Sort selector
                HStack(spacing: 8) {
                    Text("Sort:")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 13, design: .rounded))
                    .frame(width: 150)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: sortOption) { _, _ in
                    filterAndSortBooks()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(paginatedBooks.enumerated()), id: \.element.id) { index, book in
                        ModernBookRow(
                            book: book,
                            isAlternate: index % 2 != 0,
                            navigationPath: $navigationPath,
                            onEdit: { bookToEdit = book },
                            onRead: { bookToRead = book },
                            onDelete: { bookToDelete = book }
                        )
                    }
                }
            }
            
            Divider()
            
            // Pagination Controls
            HStack(spacing: 20) {
                Text("\(filteredBooks.count) books")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Text("Rows:")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $rowsPerPage) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 13, design: .rounded))
                    .frame(width: 70)
                    .onChange(of: rowsPerPage) { _, _ in
                        currentPage = 0
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    Button(action: { currentPage = max(0, currentPage - 1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(currentPage == 0 ? .secondary.opacity(0.5) : .primary)
                            .frame(width: 28, height: 28)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPage == 0)
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 100)
                    
                    Button(action: { currentPage = min(totalPages - 1, currentPage + 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(currentPage >= totalPages - 1 ? .secondary.opacity(0.5) : .primary)
                            .frame(width: 28, height: 28)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPage >= totalPages - 1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(nsColor: .textBackgroundColor))
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

// MARK: - Modern Book Row

struct ModernBookRow: View {
    let book: Book
    let isAlternate: Bool
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRead: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover
            Group {
                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                    }
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                }
            }
            .frame(width: 45, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            // Title (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
            }) {
                Text(book.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(width: 220, alignment: .leading)
                    .lineLimit(2)
            }
            .buttonStyle(.plain)
            
            // Series (clickable)
            if let series = book.series {
                Button(action: {
                    navigationPath.append(NavigationDestination.series(name: series))
                }) {
                    Text(book.seriesDisplay ?? series)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(width: 150, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 150, alignment: .leading)
            }
            
            // Author (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.author(name: book.author))
            }) {
                Text(book.author)
                    .font(.system(size: 13, design: .rounded))
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
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(width: 120, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 120, alignment: .leading)
            }
            
            // Page Count
            Text("\(book.pageCount)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                ActionButton(
                    icon: "arrow.up.right.circle.fill",
                    color: .blue,
                    action: {
                        navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                    },
                    tooltip: "Open book details"
                )
                
                ActionButton(
                    icon: "pencil.circle.fill",
                    color: .orange,
                    action: onEdit,
                    tooltip: "Edit book"
                )
                
                ActionButton(
                    icon: "book.circle.fill",
                    color: .green,
                    action: onRead,
                    tooltip: "Start reading"
                )
                
                ActionButton(
                    icon: "trash.circle.fill",
                    color: .red,
                    action: onDelete,
                    tooltip: "Delete book"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            isAlternate ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "667eea").opacity(0.08), Color(hex: "764ba2").opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(isHovered ? 1.0 : 0.0)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    let tooltip: String
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isHovered ? .white : color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isHovered ? color : color.opacity(0.12))
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(isHovered ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    LibraryView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
