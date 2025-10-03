import SwiftUI

struct GenreView: View {
    let genreName: String
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
    @State private var sortAscending: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    enum SortOption: String, CaseIterable {
        case author = "Author"
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
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Genre")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(genreName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Divider()

            HStack(spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search \(genreName) books...", text: $searchText)
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
                    
                    Button(action: {
                        sortAscending.toggle()
                        filterAndSortBooks()
                    }) {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(sortAscending ? "Ascending" : "Descending")
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

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(paginatedBooks.enumerated()), id: \.element.book.id) { index, item in
                        GenreBookRow(
                            bookWithLocation: item,
                            isAlternate: index % 2 != 0,
                            navigationPath: $navigationPath,
                            onEdit: { bookToEdit = item.book },
                            onRead: { bookToRead = item.book },
                            onDelete: { bookToDelete = item.book }
                        )
                    }
                }
            }
            
            Divider()

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
        let allBooks = dbManager.getAllBooks().filter { $0.genre == genreName }
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

        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.book.title.localizedCaseInsensitiveContains(searchText) ||
                item.book.author.localizedCaseInsensitiveContains(searchText) ||
                (item.book.series?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        switch sortOption {
        case .author:
            filtered.sort { sortAscending ? $0.book.author < $1.book.author : $0.book.author > $1.book.author }
        case .title:
            filtered.sort { sortAscending ? $0.book.title < $1.book.title : $0.book.title > $1.book.title }
        case .pageCount:
            filtered.sort { sortAscending ? $0.book.pageCount < $1.book.pageCount : $0.book.pageCount > $1.book.pageCount }
        case .dateAdded:
            filtered.sort { sortAscending ? $0.book.dateAdded < $1.book.dateAdded : $0.book.dateAdded > $1.book.dateAdded }
        }
        
        filteredBooks = filtered
        currentPage = 0
    }
}

struct GenreBookRow: View {
    let bookWithLocation: BookWithLocation
    let isAlternate: Bool
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRead: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered: Bool = false
    
    var book: Book {
        bookWithLocation.book
    }
    
    var location: BookLocation {
        bookWithLocation.location
    }
    
    var body: some View {
        HStack(spacing: 16) {
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

            Text("\(book.pageCount)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(location.displayName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(location.color.opacity(0.15))
                .foregroundColor(location.color)
                .clipShape(Capsule())
                .frame(width: 100, alignment: .leading)
            
            Spacer()

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
                
                if location == .library {
                    ActionButton(
                        icon: "book.circle.fill",
                        color: .green,
                        action: onRead,
                        tooltip: "Start reading"
                    )
                }
                
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
