//
//  ReadingTrackerView.swift
//  Booklet
//
//  Reading tracker with progress tracking and actions
//

import SwiftUI

struct ReadingTrackerView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var trackedBooks: [ReadingTrackerEntry] = []
    @State private var entryToComplete: ReadingTrackerEntry?
    @State private var entryToAbandon: ReadingTrackerEntry?
    @State private var entryToRemove: ReadingTrackerEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Reading Tracker")
                .font(.system(size: 32, weight: .bold))
                .padding(20)
            
            Divider()
            
            if trackedBooks.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No books currently being tracked")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(trackedBooks) { entry in
                            if let book = entry.book {
                                TrackedBookCard(
                                    entry: entry,
                                    book: book,
                                    navigationPath: $navigationPath,
                                    onUpdate: { newPage in
                                        _ = dbManager.updateReadingProgress(id: entry.id, currentPage: newPage)
                                        loadTrackedBooks()
                                    },
                                    onComplete: {
                                        entryToComplete = entry
                                    },
                                    onAbandon: {
                                        entryToAbandon = entry
                                    },
                                    onRemove: {
                                        entryToRemove = entry
                                    }
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(item: $entryToComplete) { entry in
            if let book = entry.book {
                CompleteBookModal(
                    isPresented: Binding(
                        get: { entryToComplete != nil },
                        set: { if !$0 { entryToComplete = nil } }
                    ),
                    entry: entry,
                    book: book,
                    dbManager: dbManager,
                    onSave: {
                        loadTrackedBooks()
                        entryToComplete = nil
                    }
                )
            }
        }
        .sheet(item: $entryToAbandon) { entry in
            if let book = entry.book {
                AbandonBookModal(
                    isPresented: Binding(
                        get: { entryToAbandon != nil },
                        set: { if !$0 { entryToAbandon = nil } }
                    ),
                    entry: entry,
                    book: book,
                    dbManager: dbManager,
                    onSave: {
                        loadTrackedBooks()
                        entryToAbandon = nil
                    }
                )
            }
        }
        .alert("Remove from Tracker?", isPresented: Binding(
            get: { entryToRemove != nil },
            set: { if !$0 { entryToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                entryToRemove = nil
            }
            Button("Remove") {
                if let entry = entryToRemove {
                    _ = dbManager.removeFromReadingTracker(id: entry.id)
                    loadTrackedBooks()
                    entryToRemove = nil
                }
            }
        } message: {
            if let entry = entryToRemove, let book = entry.book {
                Text("Remove \"\(book.title)\" from tracker? Progress will be lost and the book will return to the library.")
            }
        }
        .onAppear {
            loadTrackedBooks()
        }
    }
    
    private func loadTrackedBooks() {
        trackedBooks = dbManager.getAllTrackedBooks()
    }
}

struct TrackedBookCard: View {
    let entry: ReadingTrackerEntry
    let book: Book
    @Binding var navigationPath: NavigationPath
    let onUpdate: (Int) -> Void
    let onComplete: () -> Void
    let onAbandon: () -> Void
    let onRemove: () -> Void
    
    @State private var currentPageText: String
    
    init(entry: ReadingTrackerEntry, book: Book, navigationPath: Binding<NavigationPath>, onUpdate: @escaping (Int) -> Void, onComplete: @escaping () -> Void, onAbandon: @escaping () -> Void, onRemove: @escaping () -> Void) {
        self.entry = entry
        self.book = book
        self._navigationPath = navigationPath
        self.onUpdate = onUpdate
        self.onComplete = onComplete
        self.onAbandon = onAbandon
        self.onRemove = onRemove
        _currentPageText = State(initialValue: String(entry.currentPage))
    }
    
    var body: some View {
        HStack(spacing: 20) {
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
                .frame(width: 80, height: 120)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title (clickable)
                Button(action: {
                    navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                }) {
                    Text(book.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                // Series (clickable)
                if let seriesDisplay = book.seriesDisplay, let series = book.series {
                    Button(action: {
                        navigationPath.append(NavigationDestination.series(name: series))
                    }) {
                        Text(seriesDisplay)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                // Author (clickable)
                Button(action: {
                    navigationPath.append(NavigationDestination.author(name: book.author))
                }) {
                    Text(book.author)
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
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
                    }
                    .buttonStyle(.plain)
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Progress: \(Int(entry.progressPercentage))%")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 10)
                                .cornerRadius(5)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * (entry.progressPercentage / 100.0), height: 10)
                                .cornerRadius(5)
                        }
                    }
                    .frame(height: 10)
                }
                .frame(maxWidth: 400)
                
                // Current Page Input
                HStack(spacing: 10) {
                    TextField("Page", text: $currentPageText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    
                    Text("/ \(book.pageCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button("Update") {
                        if let page = Int(currentPageText) {
                            onUpdate(page)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 10) {
                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button("Abandon") {
                    onAbandon()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button("Remove") {
                    onRemove()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CompleteBookModal: View {
    @Binding var isPresented: Bool
    let entry: ReadingTrackerEntry
    let book: Book
    let dbManager: DatabaseManager
    let onSave: () -> Void
    
    @State private var rating: Int = 3
    @State private var review: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Complete Book")
                .font(.system(size: 20, weight: .semibold))
            
            Form {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text("by \(book.author)")
                    .foregroundColor(.secondary)
                
                Divider()
                
                HStack(spacing: 8) {
                    Text("Rating:")
                        .font(.system(size: 14, weight: .medium))
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { rating = star }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(star <= rating ? .yellow : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                TextField("Review (Optional)", text: $review, axis: .vertical)
                    .lineLimit(4...8)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Complete Book") {
                    completeBook()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func completeBook() {
        let success = dbManager.completeBook(
            trackerId: entry.id,
            bookId: book.id,
            rating: rating,
            review: review.isEmpty ? nil : review,
            startDate: entry.startDate
        )
        
        if success {
            isPresented = false
            onSave()
        }
    }
}

struct AbandonBookModal: View {
    @Binding var isPresented: Bool
    let entry: ReadingTrackerEntry
    let book: Book
    let dbManager: DatabaseManager
    let onSave: () -> Void
    
    @State private var reason: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Abandon Book")
                .font(.system(size: 20, weight: .semibold))
            
            Form {
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text("by \(book.author)")
                    .foregroundColor(.secondary)
                
                Text("Current page: \(entry.currentPage) / \(book.pageCount)")
                    .foregroundColor(.secondary)
                
                Divider()
                
                TextField("Reason (Optional)", text: $reason, axis: .vertical)
                    .lineLimit(4...8)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Abandon Book") {
                    abandonBook()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private func abandonBook() {
        let success = dbManager.abandonBook(
            trackerId: entry.id,
            bookId: book.id,
            pageAtAbandonment: entry.currentPage,
            reason: reason.isEmpty ? nil : reason,
            startDate: entry.startDate
        )
        
        if success {
            isPresented = false
            onSave()
        }
    }
}

#Preview {
    ReadingTrackerView(navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
