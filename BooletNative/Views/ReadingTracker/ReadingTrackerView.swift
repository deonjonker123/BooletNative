//
//  ReadingTrackerView.swift
//  Booklet
//
//  Reading tracker with modern design and progress tracking
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
            HStack {
                Text("Reading Tracker")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
                
                if !trackedBooks.isEmpty {
                    Text("\(trackedBooks.count) book\(trackedBooks.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(24)
            .padding(.bottom, 8)
            
            Divider()
            
            if trackedBooks.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange.opacity(0.6), .pink.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("No books currently being tracked")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Start tracking a book from your library to see it here")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(trackedBooks) { entry in
                            if let book = entry.book {
                                ModernTrackedBookCard(
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
                    .padding(24)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
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

// MARK: - Modern Tracked Book Card

struct ModernTrackedBookCard: View {
    let entry: ReadingTrackerEntry
    let book: Book
    @Binding var navigationPath: NavigationPath
    let onUpdate: (Int) -> Void
    let onComplete: () -> Void
    let onAbandon: () -> Void
    let onRemove: () -> Void
    
    @State private var currentPageText: String
    @State private var isHovered: Bool = false
    
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
        HStack(spacing: 24) {
            // Cover
            Button(action: {
                navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
            }) {
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
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Title & Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                    }) {
                        Text(book.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 10) {
                        // Series
                        if let seriesDisplay = book.seriesDisplay, let series = book.series {
                            Button(action: {
                                navigationPath.append(NavigationDestination.series(name: series))
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "books.vertical.fill")
                                        .font(.system(size: 11))
                                    Text(seriesDisplay)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Author
                        Button(action: {
                            navigationPath.append(NavigationDestination.author(name: book.author))
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 11))
                                Text(book.author)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // Genre
                        if let genre = book.genre {
                            Button(action: {
                                navigationPath.append(NavigationDestination.genre(name: genre))
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag.fill")
                                        .font(.system(size: 11))
                                    Text(genre)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(entry.progressPercentage))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (entry.progressPercentage / 100.0), height: 10)
                        }
                    }
                    .frame(height: 10)
                    
                    // Page Input
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Page", text: $currentPageText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                            
                            Text("/ \(book.pageCount)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            if let page = Int(currentPageText) {
                                onUpdate(page)
                            }
                        }) {
                            Text("Update")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 10) {
                TrackerActionButton(
                    title: "Complete",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    action: onComplete
                )
                
                TrackerActionButton(
                    title: "Abandon",
                    icon: "xmark.circle.fill",
                    color: .orange,
                    action: onAbandon
                )
                
                TrackerActionButton(
                    title: "Remove",
                    icon: "trash.circle.fill",
                    color: .red,
                    action: onRemove
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 16 : 10, x: 0, y: isHovered ? 8 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isHovered ? [Color(hex: "f093fb").opacity(0.3), Color(hex: "f5576c").opacity(0.3)] : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Tracker Action Button

struct TrackerActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isHovered ? .white : color)
            .frame(width: 130)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? color : color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(isHovered ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Complete Book Modal

struct CompleteBookModal: View {
    @Binding var isPresented: Bool
    let entry: ReadingTrackerEntry
    let book: Book
    let dbManager: DatabaseManager
    let onSave: () -> Void
    
    @State private var rating: Int = 3
    @State private var review: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Complete Book")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal],
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("by \(book.author)")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Rating
                VStack(alignment: .leading, spacing: 12) {
                    Label("Rating", systemImage: "star.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 28))
                                    .foregroundColor(star <= rating ? .yellow : .secondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Review
                VStack(alignment: .leading, spacing: 12) {
                    Label("Review (Optional)", systemImage: "text.alignleft")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $review)
                        .font(.system(size: 14, design: .rounded))
                        .frame(height: 120)
                        .padding(12)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { isPresented = false }) {
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
                
                Button(action: completeBook) {
                    Text("Complete Book")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color(hex: "11998e").opacity(0.4), radius: 8, x: 0, y: 4)
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

// MARK: - Abandon Book Modal

struct AbandonBookModal: View {
    @Binding var isPresented: Bool
    let entry: ReadingTrackerEntry
    let book: Book
    let dbManager: DatabaseManager
    let onSave: () -> Void
    
    @State private var reason: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Abandon Book")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
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
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("by \(book.author)")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text("Current page: \(entry.currentPage) / \(book.pageCount)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Reason
                VStack(alignment: .leading, spacing: 12) {
                    Label("Reason (Optional)", systemImage: "text.alignleft")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $reason)
                        .font(.system(size: 14, design: .rounded))
                        .frame(height: 120)
                        .padding(12)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { isPresented = false }) {
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
                
                Button(action: abandonBook) {
                    Text("Abandon Book")
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
