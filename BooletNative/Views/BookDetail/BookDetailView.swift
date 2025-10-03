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
                VStack(alignment: .leading, spacing: 0) {
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

                        HStack(spacing: 10) {
                            ModernActionButton(
                                title: "Edit",
                                icon: "pencil.circle.fill",
                                color: .orange,
                                action: { showEditModal = true }
                            )
                            
                            if bookLocation == .library {
                                ModernActionButton(
                                    title: "Read",
                                    icon: "book.circle.fill",
                                    color: .green,
                                    action: { showReadConfirm = true }
                                )
                            }
                            
                            ModernActionButton(
                                title: "Delete",
                                icon: "trash.circle.fill",
                                color: .red,
                                action: { showDeleteConfirm = true }
                            )
                        }
                    }
                    .padding(24)
                    .padding(.bottom, 8)
                    
                    Divider()

                    HStack(alignment: .top, spacing: 40) {
                        VStack {
                            Group {
                                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                } else {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .frame(width: 240, height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            Text(book.title)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let seriesDisplay = book.seriesDisplay, let series = book.series {
                                    Button(action: {
                                        navigationPath.append(NavigationDestination.series(name: series))
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "books.vertical.fill")
                                                .font(.system(size: 16))
                                            Text(seriesDisplay)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

                                Button(action: {
                                    navigationPath.append(NavigationDestination.author(name: book.author))
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                        Text(book.author)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                if let genre = book.genre {
                                    Button(action: {
                                        navigationPath.append(NavigationDestination.genre(name: genre))
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 16))
                                            Text(genre)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                MetadataRow(icon: "doc.text.fill", text: "\(book.pageCount) pages")
                                MetadataRow(icon: "calendar.circle.fill", text: "Added \(dateFormatter.string(from: book.dateAdded))")
                            }

                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                Text(locationText)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(locationColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(locationColor.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(30)
                    
                    Divider()

                    if let synopsis = book.synopsis {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Synopsis", systemImage: "text.alignleft")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(synopsis)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(30)
                        
                        Divider()
                    }

                    if let completed = completedEntry {
                        CompletedDetailsSection(completed: completed, dateFormatter: dateFormatter)
                            .padding(30)
                        Divider()
                    }
                    
                    if let abandoned = abandonedEntry {
                        AbandonedDetailsSection(abandoned: abandoned, book: book, dateFormatter: dateFormatter)
                            .padding(30)
                        Divider()
                    }
                    
                    if let tracker = trackerEntry {
                        TrackingDetailsSection(tracker: tracker, book: book, dateFormatter: dateFormatter)
                            .padding(30)
                        Divider()
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading book...")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
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

struct MetadataRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

struct ModernActionButton: View {
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
            .padding(.horizontal, 18)
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

struct CompletedDetailsSection: View {
    let completed: CompletedBook
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Completion Details", systemImage: "checkmark.seal.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 12) {
                if let rating = completed.rating {
                    HStack(spacing: 6) {
                        Text("Rating:")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(star <= rating ? .yellow : .secondary.opacity(0.3))
                        }
                    }
                }
                
                if let startDate = completed.startDate {
                    MetadataRow(icon: "play.circle.fill", text: "Started: \(dateFormatter.string(from: startDate))")
                }
                
                MetadataRow(icon: "checkmark.circle.fill", text: "Completed: \(dateFormatter.string(from: completed.completionDate))")
                
                if let days = completed.daysToComplete {
                    MetadataRow(icon: "clock.fill", text: "Time to complete: \(days) days")
                }
                
                if let review = completed.review, !review.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Review")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(review)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

struct AbandonedDetailsSection: View {
    let abandoned: AbandonedBook
    let book: Book
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Abandonment Details", systemImage: "xmark.circle.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 12) {
                if let page = abandoned.pageAtAbandonment {
                    MetadataRow(icon: "book.pages.fill", text: "Stopped at page: \(page) / \(book.pageCount)")
                    
                    if let progress = abandoned.progressPercentage {
                        MetadataRow(icon: "chart.pie.fill", text: "Progress: \(Int(progress))%")
                    }
                }
                
                if let startDate = abandoned.startDate {
                    MetadataRow(icon: "play.circle.fill", text: "Started: \(dateFormatter.string(from: startDate))")
                }
                
                MetadataRow(icon: "xmark.circle.fill", text: "Abandoned: \(dateFormatter.string(from: abandoned.abandonmentDate))")
                
                if let reason = abandoned.reason, !reason.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reason")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(reason)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

struct TrackingDetailsSection: View {
    let tracker: ReadingTrackerEntry
    let book: Book
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reading Progress", systemImage: "book.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 12) {
                MetadataRow(icon: "book.pages.fill", text: "Current page: \(tracker.currentPage) / \(book.pageCount)")
                MetadataRow(icon: "chart.pie.fill", text: "Progress: \(Int(tracker.progressPercentage))%")
                MetadataRow(icon: "play.circle.fill", text: "Started: \(dateFormatter.string(from: tracker.startDate))")

                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 12)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "f093fb"), Color(hex: "f5576c")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (tracker.progressPercentage / 100.0), height: 12)
                        }
                    }
                    .frame(height: 12)
                    .frame(maxWidth: 500)
                }
            }
        }
    }
}
