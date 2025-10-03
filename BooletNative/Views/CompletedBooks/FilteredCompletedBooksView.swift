import SwiftUI

enum CompletedBooksFilterType: Hashable {
    case author
    case genre
    case rating
}

struct FilteredCompletedBooksView: View {
    let filterType: CompletedBooksFilterType
    let filterValue: String
    let timePeriod: String
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
    
    @Environment(\.dismiss) var dismiss
    
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
    
    var filterDisplayText: String {
        "\(filterValue) (\(timePeriod))"
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
                    Text("Completed Books")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(filterDisplayText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .teal],
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
                    
                    TextField("Search completed books...", text: $searchText)
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
                    ForEach(Array(paginatedBooks.enumerated()), id: \.element.id) { index, completed in
                        if let book = completed.book {
                            CompletedBookRow(
                                completed: completed,
                                book: book,
                                isAlternate: index % 2 != 0,
                                navigationPath: $navigationPath,
                                onEdit: { bookToEdit = completed },
                                onRemove: { bookToRemove = completed }
                            )
                        }
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
        let allCompleted = dbManager.getAllCompletedBooks()

        var booksInPeriod: [CompletedBook] = []
        if timePeriod == "All Time" {
            booksInPeriod = allCompleted
        } else if let year = Int(timePeriod) {
            booksInPeriod = allCompleted.filter {
                Calendar.current.component(.year, from: $0.completionDate) == year
            }
        }

        switch filterType {
        case .author:
            if filterValue.isEmpty {
                completedBooks = booksInPeriod
            } else {
                completedBooks = booksInPeriod.filter { $0.book?.author == filterValue }
            }
        case .genre:
            completedBooks = booksInPeriod.filter { $0.book?.genre == filterValue }
        case .rating:
            if let ratingValue = Int(filterValue) {
                completedBooks = booksInPeriod.filter { $0.rating == ratingValue }
            } else {
                completedBooks = []
            }
        }
        
        filterAndSortBooks()
    }
    
    private func filterAndSortBooks() {
        var filtered = completedBooks

        if !searchText.isEmpty {
            filtered = filtered.filter { completed in
                guard let book = completed.book else { return false }
                return book.title.localizedCaseInsensitiveContains(searchText) ||
                       book.author.localizedCaseInsensitiveContains(searchText) ||
                       (book.series?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                       (book.genre?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

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
