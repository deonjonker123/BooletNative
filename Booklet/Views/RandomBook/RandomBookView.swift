import SwiftUI

struct RandomBookView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var selectedBook: Book?
    @State private var bookLocation: BookLocation = .library
    @State private var filterAuthor: String = ""
    @State private var filterGenre: String = ""
    @State private var filterPageCountMin: String = ""
    @State private var filterPageCountMax: String = ""
    @State private var showConfirmRead: Bool = false
    @State private var isRolling: Bool = false
    
    enum BookLocation: String {
        case library = "Library"
        case completed = "Completed"
        case abandoned = "Abandoned"
        case tracking = "Tracking"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Random Book Selector")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Let fate decide your next read")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                        Text("Filters")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !filterAuthor.isEmpty || !filterGenre.isEmpty || !filterPageCountMin.isEmpty || !filterPageCountMax.isEmpty {
                            Button(action: clearFilters) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Clear")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        FilterField(
                            label: "Author",
                            icon: "person.fill",
                            placeholder: "Any author",
                            text: $filterAuthor
                        )
                        
                        FilterField(
                            label: "Genre",
                            icon: "tag.fill",
                            placeholder: "Any genre",
                            text: $filterGenre
                        )
                        
                        FilterField(
                            label: "Min Pages",
                            icon: "book.closed.fill",
                            placeholder: "0",
                            text: $filterPageCountMin
                        )
                        
                        FilterField(
                            label: "Max Pages",
                            icon: "book.closed.fill",
                            placeholder: "9999",
                            text: $filterPageCountMax
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .padding(.horizontal, 32)

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        isRolling = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        selectRandomBook()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isRolling = false
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .rotationEffect(.degrees(isRolling ? 360 : 0))
                        Text("Roll the Dice")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 12, x: 0, y: 6)
                    .scaleEffect(isRolling ? 0.95 : 1.0)
                }
                .buttonStyle(.plain)
                .disabled(isRolling)

                if let book = selectedBook {
                    VStack(spacing: 24) {
                        Divider()
                            .padding(.horizontal, 32)
                        
                        SelectedBookCard(
                            book: book,
                            location: bookLocation,
                            navigationPath: $navigationPath,
                            onRead: { showConfirmRead = true }
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .alert("Send to Reading Tracker?", isPresented: $showConfirmRead) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                if let book = selectedBook {
                    _ = dbManager.addToReadingTracker(bookId: book.id)
                    selectedBook = nil
                }
            }
        } message: {
            if let book = selectedBook {
                Text("Send \"\(book.title)\" to reading tracker?")
            }
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
    
    private func clearFilters() {
        filterAuthor = ""
        filterGenre = ""
        filterPageCountMin = ""
        filterPageCountMax = ""
    }
    
    private func selectRandomBook() {
        let allBooks = dbManager.getAllBooks()
        let completedBooks = dbManager.getAllCompletedBooks()
        let trackedBooks = dbManager.getAllTrackedBooks()
        let abandonedBooks = dbManager.getAllAbandonedBooks()

        let completedIds = Set(completedBooks.map { $0.bookId })
        let trackedIds = Set(trackedBooks.map { $0.bookId })
        let abandonedIds = Set(abandonedBooks.map { $0.bookId })

        let libraryBooks = allBooks.filter { book in
            !completedIds.contains(book.id) &&
            !trackedIds.contains(book.id) &&
            !abandonedIds.contains(book.id)
        }

        let lastCompleted = completedBooks.first

        var eligibleBooks = libraryBooks.filter { book in
            if !filterAuthor.isEmpty && !book.author.localizedCaseInsensitiveContains(filterAuthor) {
                return false
            }
            
            if !filterGenre.isEmpty, let genre = book.genre, !genre.localizedCaseInsensitiveContains(filterGenre) {
                return false
            }
            
            if let minPages = Int(filterPageCountMin), book.pageCount < minPages {
                return false
            }
            
            if let maxPages = Int(filterPageCountMax), book.pageCount > maxPages {
                return false
            }

            if let last = lastCompleted, let lastBook = last.book {
                if book.genre == lastBook.genre && book.genre != nil {
                    return false
                }
                if book.author == lastBook.author {
                    return false
                }
                if book.series == lastBook.series && book.series != nil {
                    return false
                }
                if lastBook.pageCount > 800 && book.pageCount >= 600 {
                    return false
                }
            }

            if let series = book.series, let seriesNumber = book.seriesNumber, seriesNumber > 1 {
                let previousNumber = seriesNumber - 1
                let previousCompleted = completedBooks.contains { completed in
                    completed.book?.series == series && completed.book?.seriesNumber == previousNumber
                }
                let lastCompletedIsSameSeries = lastCompleted?.book?.series == series
                if !previousCompleted && !lastCompletedIsSameSeries {
                    return false
                }
            }
            
            return true
        }

        if let randomBook = eligibleBooks.randomElement() {
            selectedBook = randomBook
            bookLocation = .library
        } else {
            selectedBook = nil
        }
    }
}

struct FilterField: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct SelectedBookCard: View {
    let book: Book
    let location: RandomBookView.BookLocation
    @Binding var navigationPath: NavigationPath
    let onRead: () -> Void
    
    @State private var isHovered: Bool = false
    
    var locationColor: Color {
        switch location {
        case .library: return .blue
        case .completed: return .green
        case .abandoned: return .red
        case .tracking: return .orange
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 32) {
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
                .frame(width: 200, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                }) {
                    Text(book.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    if let seriesDisplay = book.seriesDisplay, let series = book.series {
                        Button(action: {
                            navigationPath.append(NavigationDestination.series(name: series))
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 13))
                                Text(seriesDisplay)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        navigationPath.append(NavigationDestination.author(name: book.author))
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 13))
                            Text(book.author)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    if let genre = book.genre {
                        Button(action: {
                            navigationPath.append(NavigationDestination.genre(name: genre))
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 13))
                                Text(genre)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("\(book.pageCount) pages")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(locationColor)
                        Text(location.rawValue)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(locationColor)
                    }
                }

                if let synopsis = book.synopsis {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Synopsis")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(synopsis)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(6)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: {
                        navigationPath.append(NavigationDestination.bookDetail(bookId: book.id))
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("View Details")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    if location == .library {
                        Button(action: onRead) {
                            HStack(spacing: 8) {
                                Image(systemName: "book.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Start Reading")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
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
                    }
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 20 : 12, x: 0, y: isHovered ? 10 : 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: isHovered ? [Color(hex: "667eea").opacity(0.3), Color(hex: "764ba2").opacity(0.3)] : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .padding(.horizontal, 32)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
