//
//  BookTable.swift
//  Booklet
//
//  Reusable book table component with pagination and actions
//

import SwiftUI

struct BookTable<Item: Identifiable>: View {
    let items: [Item]
    let columns: [TableColumn]
    let rowContent: (Item) -> [String]
    let actions: (Item) -> [TableAction]
    @Binding var currentPage: Int
    @Binding var rowsPerPage: Int
    
    struct TableColumn {
        let title: String
        let width: CGFloat
    }
    
    struct TableAction {
        let title: String
        let color: Color
        let action: () -> Void
    }
    
    var paginatedItems: [Item] {
        let start = currentPage * rowsPerPage
        let end = min(start + rowsPerPage, items.count)
        guard start < items.count else { return [] }
        return Array(items[start..<end])
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(items.count) / Double(rowsPerPage))))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 10) {
                ForEach(columns.indices, id: \.self) { index in
                    Text(columns[index].title)
                        .frame(width: columns[index].width, alignment: .leading)
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(paginatedItems) { item in
                        TableRow<Item>(
                            columns: columns,
                            content: rowContent(item),
                            actions: actions(item)
                        )
                        Divider()
                    }
                }
            }
            
            Divider()
            
            // Pagination Controls
            HStack {
                Text("\(items.count) items")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 10) {
                    Text("Rows per page:")
                        .font(.system(size: 13))
                    
                    Picker("", selection: $rowsPerPage) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                    .onChange(of: rowsPerPage) { _, _ in
                        currentPage = 0
                    }
                    
                    Button(action: { currentPage = max(0, currentPage - 1) }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentPage == 0)
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.system(size: 13))
                        .frame(width: 100)
                    
                    Button(action: { currentPage = min(totalPages - 1, currentPage + 1) }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
            }
            .padding(15)
        }
    }
}

struct TableRow<Item: Identifiable>: View {
    let columns: [BookTable<Item>.TableColumn]
    let content: [String]
    let actions: [BookTable<Item>.TableAction]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(zip(columns.indices, content)), id: \.0) { index, text in
                Text(text)
                    .font(.system(size: 13))
                    .frame(width: columns[index].width, alignment: .leading)
                    .lineLimit(2)
            }
            
            HStack(spacing: 8) {
                ForEach(actions.indices, id: \.self) { index in
                    Button(actions[index].title) {
                        actions[index].action()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                    .foregroundColor(actions[index].color)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// Dummy type for preview and type constraints
struct DummyIdentifiable: Identifiable {
    let id: Int
}

#Preview {
    BookTable(
        items: [DummyIdentifiable(id: 1), DummyIdentifiable(id: 2)],
        columns: [
            BookTable.TableColumn(title: "Title", width: 200),
            BookTable.TableColumn(title: "Author", width: 150)
        ],
        rowContent: { _ in ["Sample Title", "Sample Author"] },
        actions: { _ in [
            BookTable.TableAction(title: "Open", color: .blue, action: {})
        ] },
        currentPage: .constant(0),
        rowsPerPage: .constant(50)
    )
}
