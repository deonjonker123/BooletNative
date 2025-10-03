import Foundation
import SQLite3
import Combine
import Compression

class DatabaseManager: ObservableObject {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {
        openDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    private func openDatabase() {
        guard let dbPath = Bundle.main.path(forResource: "booklet", ofType: "db") else {
            print("ERROR: Database file not found in bundle")
            return
        }

        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationPath = documentsPath.appendingPathComponent("booklet.db")

        if !fileManager.fileExists(atPath: destinationPath.path) {
            do {
                try fileManager.copyItem(atPath: dbPath, toPath: destinationPath.path)
                print("Database copied to: \(destinationPath.path)")
            } catch {
                print("ERROR: Could not copy database: \(error)")
                return
            }
        }

        if sqlite3_open(destinationPath.path, &db) != SQLITE_OK {
            print("ERROR: Could not open database")
            return
        }
        
        print("Database opened successfully at: \(destinationPath.path)")
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    func getAllBooks() -> [Book] {
        var books: [Book] = []
        let query = """
            SELECT id, cover_url, title, series, series_number, author, page_count, synopsis, genre, date_added
            FROM books
            ORDER BY date_added DESC
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let book = parseBookRow(statement: statement) {
                    books.append(book)
                }
            }
        }
        
        sqlite3_finalize(statement)
        return books
    }
    
    func getBook(id: Int) -> Book? {
        let query = """
            SELECT id, cover_url, title, series, series_number, author, page_count, synopsis, genre, date_added
            FROM books
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        var book: Book?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_ROW {
                book = parseBookRow(statement: statement)
            }
        }
        
        sqlite3_finalize(statement)
        return book
    }
    
    func addBook(coverUrl: String?, title: String, series: String?, seriesNumber: Double?, author: String, pageCount: Int, synopsis: String?, genre: String?) -> Bool {
        let query = """
            INSERT INTO books (cover_url, title, series, series_number, author, page_count, synopsis, genre)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            bindText(statement: statement, index: 1, value: coverUrl)
            bindText(statement: statement, index: 2, value: title)
            bindText(statement: statement, index: 3, value: series)
            
            if let seriesNumber = seriesNumber {
                sqlite3_bind_double(statement, 4, seriesNumber)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            bindText(statement: statement, index: 5, value: author)
            sqlite3_bind_int(statement, 6, Int32(pageCount))
            bindText(statement: statement, index: 7, value: synopsis)
            bindText(statement: statement, index: 8, value: genre)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func updateBook(id: Int, coverUrl: String?, title: String, series: String?, seriesNumber: Double?, author: String, pageCount: Int, synopsis: String?, genre: String?) -> Bool {
        let query = """
            UPDATE books
            SET cover_url = ?, title = ?, series = ?, series_number = ?, author = ?, page_count = ?, synopsis = ?, genre = ?
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            bindText(statement: statement, index: 1, value: coverUrl)
            bindText(statement: statement, index: 2, value: title)
            bindText(statement: statement, index: 3, value: series)
            
            if let seriesNumber = seriesNumber {
                sqlite3_bind_double(statement, 4, seriesNumber)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            bindText(statement: statement, index: 5, value: author)
            sqlite3_bind_int(statement, 6, Int32(pageCount))
            bindText(statement: statement, index: 7, value: synopsis)
            bindText(statement: statement, index: 8, value: genre)
            sqlite3_bind_int(statement, 9, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func deleteBook(id: Int) -> Bool {
        let query = "DELETE FROM books WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllTrackedBooks() -> [ReadingTrackerEntry] {
        var entries: [ReadingTrackerEntry] = []
        let query = """
            SELECT rt.id, rt.book_id, rt.current_page, rt.start_date,
                   b.id, b.cover_url, b.title, b.series, b.series_number, b.author, b.page_count, b.synopsis, b.genre, b.date_added
            FROM reading_tracker rt
            JOIN books b ON rt.book_id = b.id
            ORDER BY rt.start_date DESC
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var entry = ReadingTrackerEntry(
                    id: Int(sqlite3_column_int(statement, 0)),
                    bookId: Int(sqlite3_column_int(statement, 1)),
                    currentPage: Int(sqlite3_column_int(statement, 2)),
                    startDate: parseDate(statement: statement, index: 3) ?? Date()
                )
                
                entry.book = parseBookRowWithOffset(statement: statement, offset: 4)
                entries.append(entry)
            }
        }
        
        sqlite3_finalize(statement)
        return entries
    }
    
    func addToReadingTracker(bookId: Int) -> Bool {
        let query = "INSERT INTO reading_tracker (book_id, current_page) VALUES (?, 0)"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(bookId))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func updateReadingProgress(id: Int, currentPage: Int) -> Bool {
        let query = "UPDATE reading_tracker SET current_page = ? WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(currentPage))
            sqlite3_bind_int(statement, 2, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func removeFromReadingTracker(id: Int) -> Bool {
        let query = "DELETE FROM reading_tracker WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func completeBook(trackerId: Int, bookId: Int, rating: Int?, review: String?, startDate: Date?) -> Bool {
        let insertQuery = """
            INSERT INTO completed_books (book_id, rating, review, start_date)
            VALUES (?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(bookId))
            
            if let rating = rating {
                sqlite3_bind_int(statement, 2, Int32(rating))
            } else {
                sqlite3_bind_null(statement, 2)
            }
            
            bindText(statement: statement, index: 3, value: review)
            
            if let startDate = startDate {
                bindDate(statement: statement, index: 4, date: startDate)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return removeFromReadingTracker(id: trackerId)
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func abandonBook(trackerId: Int, bookId: Int, pageAtAbandonment: Int?, reason: String?, startDate: Date?) -> Bool {
        let insertQuery = """
            INSERT INTO abandoned_books (book_id, page_at_abandonment, reason, start_date)
            VALUES (?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(bookId))
            
            if let page = pageAtAbandonment {
                sqlite3_bind_int(statement, 2, Int32(page))
            } else {
                sqlite3_bind_null(statement, 2)
            }
            
            bindText(statement: statement, index: 3, value: reason)
            
            if let startDate = startDate {
                bindDate(statement: statement, index: 4, date: startDate)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return removeFromReadingTracker(id: trackerId)
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllCompletedBooks() -> [CompletedBook] {
        var completed: [CompletedBook] = []
        let query = """
            SELECT cb.id, cb.book_id, cb.rating, cb.review, cb.start_date, cb.completion_date,
                   b.id, b.cover_url, b.title, b.series, b.series_number, b.author, b.page_count, b.synopsis, b.genre, b.date_added
            FROM completed_books cb
            JOIN books b ON cb.book_id = b.id
            ORDER BY cb.completion_date DESC
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var entry = CompletedBook(
                    id: Int(sqlite3_column_int(statement, 0)),
                    bookId: Int(sqlite3_column_int(statement, 1)),
                    rating: sqlite3_column_type(statement, 2) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 2)) : nil,
                    review: parseText(statement: statement, index: 3),
                    startDate: parseDate(statement: statement, index: 4),
                    completionDate: parseDate(statement: statement, index: 5) ?? Date()
                )

                entry.book = parseBookRowWithOffset(statement: statement, offset: 6)
                completed.append(entry)
            }
        }
        
        sqlite3_finalize(statement)
        return completed
    }
    
    func updateCompletedBook(id: Int, rating: Int?, review: String?, startDate: Date?, completionDate: Date) -> Bool {
        let query = """
            UPDATE completed_books
            SET rating = ?, review = ?, start_date = ?, completion_date = ?
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if let rating = rating {
                sqlite3_bind_int(statement, 1, Int32(rating))
            } else {
                sqlite3_bind_null(statement, 1)
            }
            
            bindText(statement: statement, index: 2, value: review)
            
            if let startDate = startDate {
                bindDate(statement: statement, index: 3, date: startDate)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            bindDate(statement: statement, index: 4, date: completionDate)
            sqlite3_bind_int(statement, 5, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func removeFromCompleted(id: Int) -> Bool {
        let query = "DELETE FROM completed_books WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func getAllAbandonedBooks() -> [AbandonedBook] {
        var abandoned: [AbandonedBook] = []
        let query = """
            SELECT ab.id, ab.book_id, ab.page_at_abandonment, ab.reason, ab.start_date, ab.abandonment_date,
                   b.id, b.cover_url, b.title, b.series, b.series_number, b.author, b.page_count, b.synopsis, b.genre, b.date_added
            FROM abandoned_books ab
            JOIN books b ON ab.book_id = b.id
            ORDER BY ab.abandonment_date DESC
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var entry = AbandonedBook(
                    id: Int(sqlite3_column_int(statement, 0)),
                    bookId: Int(sqlite3_column_int(statement, 1)),
                    pageAtAbandonment: sqlite3_column_type(statement, 2) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 2)) : nil,
                    reason: parseText(statement: statement, index: 3),
                    startDate: parseDate(statement: statement, index: 4),
                    abandonmentDate: parseDate(statement: statement, index: 5) ?? Date()
                )

                entry.book = parseBookRowWithOffset(statement: statement, offset: 6)
                abandoned.append(entry)
            }
        }
        
        sqlite3_finalize(statement)
        return abandoned
    }
    
    func updateAbandonedBook(id: Int, pageAtAbandonment: Int?, reason: String?, startDate: Date?, abandonmentDate: Date) -> Bool {
        let query = """
            UPDATE abandoned_books
            SET page_at_abandonment = ?, reason = ?, start_date = ?, abandonment_date = ?
            WHERE id = ?
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if let page = pageAtAbandonment {
                sqlite3_bind_int(statement, 1, Int32(page))
            } else {
                sqlite3_bind_null(statement, 1)
            }
            
            bindText(statement: statement, index: 2, value: reason)
            
            if let startDate = startDate {
                bindDate(statement: statement, index: 3, date: startDate)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            
            bindDate(statement: statement, index: 4, date: abandonmentDate)
            sqlite3_bind_int(statement, 5, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func removeFromAbandoned(id: Int) -> Bool {
        let query = "DELETE FROM abandoned_books WHERE id = ?"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    func createBackup(to destinationURL: URL) throws {
            // Get the current database path
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dbPath = documentsPath.appendingPathComponent("booklet.db")
            
            // Verify database exists
            guard fileManager.fileExists(atPath: dbPath.path) else {
                throw BackupError.databaseNotFound
            }
            
            // Create temporary directory for backup preparation
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            // Copy database to temp directory
            let tempDBPath = tempDir.appendingPathComponent("booklet.db")
            try fileManager.copyItem(at: dbPath, to: tempDBPath)
            
            // Create ZIP archive
            try createZipArchive(sourceURL: tempDBPath, destinationURL: destinationURL)
        }
        
        func restoreBackup(from sourceURL: URL) throws {
            let fileManager = FileManager.default
            
            // Verify the source file exists and is a ZIP
            guard fileManager.fileExists(atPath: sourceURL.path) else {
                throw BackupError.backupFileNotFound
            }
            
            guard sourceURL.pathExtension.lowercased() == "zip" else {
                throw BackupError.invalidBackupFile
            }
            
            // Create temporary directory for extraction
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            // Extract ZIP
            try extractZipArchive(sourceURL: sourceURL, destinationURL: tempDir)
            
            // Verify extracted database
            let extractedDBPath = tempDir.appendingPathComponent("booklet.db")
            guard fileManager.fileExists(atPath: extractedDBPath.path) else {
                throw BackupError.invalidBackupFile
            }
            
            // Verify it's a valid SQLite database
            guard isValidSQLiteDatabase(at: extractedDBPath) else {
                throw BackupError.corruptedBackup
            }
            
            // Close current database connection
            closeDatabase()
            
            // Get current database path
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let currentDBPath = documentsPath.appendingPathComponent("booklet.db")
            
            // Remove current database
            if fileManager.fileExists(atPath: currentDBPath.path) {
                try fileManager.removeItem(at: currentDBPath)
            }
            
            // Copy restored database to documents directory
            try fileManager.copyItem(at: extractedDBPath, to: currentDBPath)
            
            // Reopen database
            openDatabase()
        }
        
        // MARK: - Private Helper Methods
        
        private func createZipArchive(sourceURL: URL, destinationURL: URL) throws {
            let fileManager = FileManager.default
            
            // Read source file
            let sourceData = try Data(contentsOf: sourceURL)
            
            // Create ZIP using Compression framework
            let compressedData = try compress(data: sourceData)
            
            // Write to destination
            try compressedData.write(to: destinationURL)
        }
        
        private func extractZipArchive(sourceURL: URL, destinationURL: URL) throws {
            // Read ZIP file
            let compressedData = try Data(contentsOf: sourceURL)
            
            // Decompress
            let decompressedData = try decompress(data: compressedData)
            
            // Write database file
            let dbPath = destinationURL.appendingPathComponent("booklet.db")
            try decompressedData.write(to: dbPath)
        }
        
        private func compress(data: Data) throws -> Data {
            let sourceBuffer = Array(data)
            let destinationBufferSize = data.count
            var destinationBuffer = [UInt8](repeating: 0, count: destinationBufferSize)
            
            let compressedSize = compression_encode_buffer(
                &destinationBuffer,
                destinationBufferSize,
                sourceBuffer,
                sourceBuffer.count,
                nil,
                COMPRESSION_ZLIB
            )
            
            guard compressedSize > 0 else {
                throw BackupError.compressionFailed
            }
            
            return Data(destinationBuffer.prefix(compressedSize))
        }
        
        private func decompress(data: Data) throws -> Data {
            let sourceBuffer = Array(data)
            // Allocate buffer size - assume max 10x compression ratio
            let destinationBufferSize = data.count * 10
            var destinationBuffer = [UInt8](repeating: 0, count: destinationBufferSize)
            
            let decompressedSize = compression_decode_buffer(
                &destinationBuffer,
                destinationBufferSize,
                sourceBuffer,
                sourceBuffer.count,
                nil,
                COMPRESSION_ZLIB
            )
            
            guard decompressedSize > 0 else {
                throw BackupError.decompressionFailed
            }
            
            return Data(destinationBuffer.prefix(decompressedSize))
        }
        
        private func isValidSQLiteDatabase(at url: URL) -> Bool {
            var testDB: OpaquePointer?
            
            guard sqlite3_open(url.path, &testDB) == SQLITE_OK else {
                sqlite3_close(testDB)
                return false
            }
            
            // Try to query sqlite_master table (exists in all SQLite databases)
            let query = "SELECT name FROM sqlite_master WHERE type='table' LIMIT 1;"
            var statement: OpaquePointer?
            
            let result = sqlite3_prepare_v2(testDB, query, -1, &statement, nil)
            sqlite3_finalize(statement)
            sqlite3_close(testDB)
            
            return result == SQLITE_OK
        }
        
        enum BackupError: LocalizedError {
            case databaseNotFound
            case backupFileNotFound
            case invalidBackupFile
            case corruptedBackup
            case compressionFailed
            case decompressionFailed
            
            var errorDescription: String? {
                switch self {
                case .databaseNotFound:
                    return "Database file not found."
                case .backupFileNotFound:
                    return "Backup file not found."
                case .invalidBackupFile:
                    return "Selected file is not a valid backup."
                case .corruptedBackup:
                    return "Backup file is corrupted or invalid."
                case .compressionFailed:
                    return "Failed to compress database."
                case .decompressionFailed:
                    return "Failed to decompress backup."
                }
            }
        }
    
    private func parseBookRow(statement: OpaquePointer?) -> Book? {
        return parseBookRowWithOffset(statement: statement, offset: 0)
    }
    
    private func parseBookRowWithOffset(statement: OpaquePointer?, offset: Int32) -> Book? {
        guard let statement = statement else { return nil }
        
        return Book(
            id: Int(sqlite3_column_int(statement, offset + 0)),
            coverUrl: parseText(statement: statement, index: offset + 1),
            title: parseText(statement: statement, index: offset + 2) ?? "",
            series: parseText(statement: statement, index: offset + 3),
            seriesNumber: sqlite3_column_type(statement, offset + 4) != SQLITE_NULL ? sqlite3_column_double(statement, offset + 4) : nil,
            author: parseText(statement: statement, index: offset + 5) ?? "",
            pageCount: Int(sqlite3_column_int(statement, offset + 6)),
            synopsis: parseText(statement: statement, index: offset + 7),
            genre: parseText(statement: statement, index: offset + 8),
            dateAdded: parseDate(statement: statement, index: offset + 9) ?? Date()
        )
    }
    
    private func parseText(statement: OpaquePointer?, index: Int32) -> String? {
        guard let statement = statement,
              sqlite3_column_type(statement, index) != SQLITE_NULL,
              let cString = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: cString)
    }
    
    private func parseDate(statement: OpaquePointer?, index: Int32) -> Date? {
        guard let dateString = parseText(statement: statement, index: index) else {
            return nil
        }
        return dateFormatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    private func bindText(statement: OpaquePointer?, index: Int32, value: String?) {
        if let value = value {
            sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
    
    private func bindDate(statement: OpaquePointer?, index: Int32, date: Date) {
        let dateString = dateFormatter.string(from: date)
        sqlite3_bind_text(statement, index, (dateString as NSString).utf8String, -1, nil)
    }
}
