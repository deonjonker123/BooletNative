//
//  AbandonedBooksView.swift
//  Booklet
//
//  View for abandoned books with modern design
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
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Divider()
            
            // Search and Sort Bar
            HStack(spacing: 15) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search abandoned books...", text: $searchText)
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
                    ForEach(Array(paginatedBooks.enumerated()), id: \.element.id) { index, abandoned in
                        if let book = abandoned.book {
                            AbandonedBookRow(
                                abandoned: abandoned,
                                book: book,
                                isAlternate: index % 2 != 0,
                                navigationPath: $navigationPath,
                                onEdit: { bookToEdit = abandoned },
                                onRemove: { bookToRemove = abandoned }
                            )
                        }
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

// MARK: - Abandoned Book Row

struct AbandonedBookRow: View {
    let abandoned: AbandonedBook
    let book: Book
    let isAlternate: Bool
    @Binding var navigationPath: NavigationPath
    let onEdit: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovered: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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
            
            // Author (clickable)
            Button(action: {
                navigationPath.append(NavigationDestination.author(name: book.author))
            }) {
                Text(book.author)
                    .font(.system(size: 13, design: .rounded))
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
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(width: 100, alignment: .leading)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 100, alignment: .leading)
            }
            
            // Page Count
            Text("\(book.pageCount)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Page at Abandonment
            if let page = abandoned.pageAtAbandonment {
                Text("\(page)")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 80, alignment: .leading)
            }
            
            // Abandonment Date
            Text(dateFormatter.string(from: abandoned.abandonmentDate))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
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
                    tooltip: "Edit abandonment details"
                )
                
                ActionButton(
                    icon: "trash.circle.fill",
                    color: .red,
                    action: onRemove,
                    tooltip: "Remove from abandoned"
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
                        colors: [Color(hex: "eb3349").opacity(0.08), Color(hex: "f45c43").opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(isHovered ? 1.0 : 0.0)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Edit Abandoned Book Modal

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
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Abandoned Book")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            Divider()
            
            VStack(spacing: 24) {
                if let book = abandoned.book {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("by \(book.author)")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // Page at Abandonment
                VStack(alignment: .leading, spacing: 12) {
                    Label("Page at Abandonment", systemImage: "book.pages")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    TextField("Page number", text: $pageAtAbandonment)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Reason
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reason", systemImage: "text.alignleft")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $reason)
                        .font(.system(size: 14, design: .rounded))
                        .frame(height: 100)
                        .padding(12)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Dates
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .font(.system(size: 14, design: .rounded))
                    
                    DatePicker("Abandonment Date", selection: $abandonmentDate, displayedComponents: .date)
                        .font(.system(size: 14, design: .rounded))
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "eb3349"), Color(hex: "f45c43")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color(hex: "eb3349").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
        .frame(width: 550)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
