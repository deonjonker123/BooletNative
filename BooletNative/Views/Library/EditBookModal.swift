import SwiftUI

struct EditBookModal: View {
    let book: Book
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var coverUrl: String
    @State private var title: String
    @State private var series: String
    @State private var seriesNumber: String
    @State private var author: String
    @State private var pageCount: String
    @State private var synopsis: String
    @State private var genre: String
    
    init(book: Book, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.book = book
        self.onSave = onSave
        self.onCancel = onCancel
        _coverUrl = State(initialValue: book.coverUrl ?? "")
        _title = State(initialValue: book.title)
        _series = State(initialValue: book.series ?? "")
        _seriesNumber = State(initialValue: book.seriesNumber != nil ? String(book.seriesNumber!) : "")
        _author = State(initialValue: book.author)
        _pageCount = State(initialValue: String(book.pageCount))
        _synopsis = State(initialValue: book.synopsis ?? "")
        _genre = State(initialValue: book.genre ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Cover Preview
            VStack(spacing: 12) {
                Text("Cover Preview")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Group {
                    if !coverUrl.isEmpty, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 180, height: 270)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 180, height: 270)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                coverPlaceholder
                            @unknown default:
                                coverPlaceholder
                            }
                        }
                    } else {
                        coverPlaceholder
                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            }
            .padding(.top, 24)
            
            Divider()
                .padding(.vertical, 16)
            
            // Form
            ScrollView {
                VStack(spacing: 18) {
                    ModernTextField(placeholder: "https://...", text: $coverUrl)
                    
                    ModernTextField(placeholder: "Book title", text: $title)
                    
                    HStack(spacing: 14) {
                        ModernTextField(placeholder: "Series name", text: $series)
                        ModernTextField(placeholder: "1 or 1.5", text: $seriesNumber)
                            .frame(width: 120)
                    }
                    
                    ModernTextField(placeholder: "Author name", text: $author)
                    
                    HStack(spacing: 14) {
                        ModernTextField(placeholder: "350", text: $pageCount)
                        ModernTextField(placeholder: "Fantasy", text: $genre)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Synopsis", systemImage: "text.alignleft")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $synopsis)
                            .font(.system(size: 13, design: .rounded))
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            
            // Divider + Action Buttons
            Divider()
            
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
                
                Button(action: saveBook) {
                    Text("Save Changes")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [Color(hex: "f093fb"), Color(hex: "f5576c")] : [Color.secondary, Color.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: isFormValid ? Color(hex: "f5576c").opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            
        }
        .frame(width: 500, height: 700)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var coverPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No Cover")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(width: 180, height: 270)
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !author.isEmpty && Int(pageCount) != nil
    }
    
    private func saveBook() {
        guard let pages = Int(pageCount) else { return }
        
        let seriesNum = Double(seriesNumber)
        
        _ = dbManager.updateBook(
            id: book.id,
            coverUrl: coverUrl.isEmpty ? nil : coverUrl,
            title: title,
            series: series.isEmpty ? nil : series,
            seriesNumber: seriesNum,
            author: author,
            pageCount: pages,
            synopsis: synopsis.isEmpty ? nil : synopsis,
            genre: genre.isEmpty ? nil : genre
        )
        
        onSave()
    }
}
