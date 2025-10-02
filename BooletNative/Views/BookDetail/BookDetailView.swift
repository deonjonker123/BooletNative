//
//  BookDetailView.swift
//  Booklet
//
//  Individual book detail page
//

import SwiftUI

struct BookDetailView: View {
    let bookId: Int
    @Binding var navigationPath: NavigationPath
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var book: Book?
    @State private var bookLocation: BookLocation = .library
    @State private var completedEntry: CompletedBook?
    @State private var abandonedEntry: AbandonedBook?
    @State private var trackerEntry: ReadingTrackerEntry?
    
    @State private var showEditModal: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showReadConfirm: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    enum BookLocation {
        case library
        case completed
        case abandoned
        case tracking
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            if let book = book {
                VStack(alignment: .leading, spacing: 30) {
                    // Header with Back Button
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                        .buttonStyle(.borderless)
                        
                        Spacer()
                        
                        // Action Buttons
                        HStack(spacing: 10) {
                            Button("Edit") {
                                showEditModal = true
                            }
                            .buttonStyle(.bordered)
                            
                            if bookLocation == .library {
                                Button("Read") {
                                    showReadConfirm = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            Button("Delete") {
                                showDeleteConfirm = true
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    
                    // Book Details
                    HStack(alignment: .top, spacing: 30) {
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
                            .frame(width: 200, height: 300)
                            .cornerRadius(12)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 300)
                                .cornerRadius(12)
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: 15) {
                            Text(book.title)
                                .font(.system(size: 32, weight: .bold))
                            
                            if let seriesDisplay = book.seriesDisplay, let series = book.series {
                                Button(action: {
                                    navigationPath.append(NavigationDestination.series(name: series))
                                }) {
                                    HStack {
                                        Image(systemName: "books.vertical")
                                        Text(seriesDisplay)
                                            .font(.system(size: 18))
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                navigationPath.append(NavigationDestination.author(name: book.author))
                            }) {
                                HStack {
                                    Image(systemName: "person")
                                    Text(book.author)
                                        .font(.system(size: 18))
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            
                            if let genre = book.genre {
                                Button(action: {
                                    navigationPath.append(NavigationDestination.genre(name: genre))
                                }) {
                                    HStack {
                                        Image(systemName: "tag")
                                        Text(genre)
                                            .font(.system(size: 16))
                                    }
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Image(systemName: "doc.text")
                                Text("\(book.pageCount) pages")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                Text("Added \(dateFormatter.string(from: book.dateAdded))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Location Badge
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                Text(locationText)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(locationColor.opacity(0.2))
                                    .foregroundColor(locationColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Synopsis
                    if let synopsis = book.synopsis {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Synopsis")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text(synopsis)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Status-specific information
                    if let completed = completedEntry {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Completion Details")
                                .font(.system(size: 20, weight: .semibold))
                            
                            if let rating = completed.rating {
                                HStack(spacing: 3) {
                                    Text("Rating:")
                                        .font(.system(size: 15, weight: .medium))
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .foregroundColor(star <= rating ? .yellow : .gray)
                                    }
                                }
                            }
                            
                            if let startDate = completed.startDate {
                                Text("Started: \(dateFormatter.string(from: startDate))")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Completed: \(dateFormatter.string(from: completed.completionDate))")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            if let days = completed.daysToComplete {
                                Text("Time to complete: \(days) days")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            
                            if let review = completed.review, !review.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Review")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text(review)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    if let abandoned = abandonedEntry {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Abandonment Details")
                                .font(.system(size: 20, weight: .semibold))
                            
                            if let page = abandoned.pageAtAbandonment {
                                Text("Stopped at page: \(page) / \(book.pageCount)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                
                                if let progress = abandoned.progressPercentage {
                                    Text("Progress: \(Int(progress))%")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let startDate = abandoned.startDate {
                                Text("Started: \(dateFormatter.string(from: startDate))")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Abandoned: \(dateFormatter.string(from: abandoned.abandonmentDate))")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            if let reason = abandoned.reason, !reason.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Reason")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text(reason)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(12)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    if let tracker = trackerEntry {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Reading Progress")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Current page: \(tracker.currentPage) / \(book.pageCount)")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Text("Progress: \(Int(tracker.progressPercentage))%")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            Text("Started: \(dateFormatter.string(from: tracker.startDate))")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 12)
                                        .cornerRadius(6)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * (tracker.progressPercentage / 100.0), height: 12)
                                        .cornerRadius(6)
                                }
                            }
                            .frame(height: 12)
                            .frame(maxWidth: 400)
                        }
                    }
                }
                .padding(30)
            } else {
                VStack(spacing: 15) {
                    ProgressView()
                    Text("Loading book...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showEditModal) {
            if let book = book {
                EditBookModal(book: book, onSave: {
                    loadBook()
                    showEditModal = false
                }, onCancel: {
                    showEditModal = false
                })
            }
        }
        .alert("Delete Book?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let book = book {
                    _ = dbManager.deleteBook(id: book.id)
                    dismiss()
                }
            }
        } message: {
            if let book = book {
                Text("Are you sure you want to delete \"\(book.title)\"? This action cannot be undone.")
            }
        }
        .alert("Send to Reading Tracker?", isPresented: $showReadConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                if let book = book {
                    _ = dbManager.addToReadingTracker(bookId: book.id)
                    loadBook()
                }
            }
        } message: {
            if let book = book {
                Text("Send \"\(book.title)\" to reading tracker?")
            }
        }
        .onAppear {
            loadBook()
        }
    }
    
    private var locationText: String {
        switch bookLocation {
        case .library: return "Library"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        case .tracking: return "Currently Reading"
        }
    }
    
    private var locationColor: Color {
        switch bookLocation {
        case .library: return .blue
        case .completed: return .green
        case .abandoned: return .red
        case .tracking: return .orange
        }
    }
    
    private func loadBook() {
        book = dbManager.getBook(id: bookId)
        
        // Determine location
        let tracked = dbManager.getAllTrackedBooks()
        let completed = dbManager.getAllCompletedBooks()
        let abandoned = dbManager.getAllAbandonedBooks()
        
        if let entry = tracked.first(where: { $0.bookId == bookId }) {
            bookLocation = .tracking
            trackerEntry = entry
        } else if let entry = completed.first(where: { $0.bookId == bookId }) {
            bookLocation = .completed
            completedEntry = entry
        } else if let entry = abandoned.first(where: { $0.bookId == bookId }) {
            bookLocation = .abandoned
            abandonedEntry = entry
        } else {
            bookLocation = .library
        }
    }
}

#Preview {
    BookDetailView(bookId: 1, navigationPath: .constant(NavigationPath()))
        .environmentObject(DatabaseManager.shared)
}
