//
//  AddBookModal.swift
//  Booklet
//
//  Modal for adding new books manually
//

import SwiftUI

struct AddBookModal: View {
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var coverUrl: String = ""
    @State private var title: String = ""
    @State private var series: String = ""
    @State private var seriesNumber: String = ""
    @State private var author: String = ""
    @State private var pageCount: String = ""
    @State private var synopsis: String = ""
    @State private var genre: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Book")
                .font(.system(size: 20, weight: .semibold))
            
            Form {
                TextField("Cover URL", text: $coverUrl)
                    .help("Direct URL to book cover image")
                
                TextField("Title *", text: $title)
                
                TextField("Series", text: $series)
                
                TextField("Series Number", text: $seriesNumber)
                    .help("Decimals allowed (e.g., 2.5)")
                
                TextField("Author *", text: $author)
                
                TextField("Page Count *", text: $pageCount)
                
                TextField("Genre", text: $genre)
                
                TextField("Synopsis", text: $synopsis, axis: .vertical)
                    .lineLimit(4...8)
            }
            .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Book") {
                    addBook()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !author.isEmpty && Int(pageCount) != nil
    }
    
    private func addBook() {
        guard let pages = Int(pageCount) else { return }
        
        let seriesNum = Double(seriesNumber)
        
        let success = dbManager.addBook(
            coverUrl: coverUrl.isEmpty ? nil : coverUrl,
            title: title,
            series: series.isEmpty ? nil : series,
            seriesNumber: seriesNum,
            author: author,
            pageCount: pages,
            synopsis: synopsis.isEmpty ? nil : synopsis,
            genre: genre.isEmpty ? nil : genre
        )
        
        if success {
            isPresented = false
            onSave()
        }
    }
}

#Preview {
    AddBookModal(isPresented: .constant(true), onSave: {})
        .environmentObject(DatabaseManager.shared)
}
