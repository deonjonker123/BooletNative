import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct BackupRestoreView: View {
    @EnvironmentObject var dbManager: DatabaseManager
    @State private var showBackupSuccess: Bool = false
    @State private var showBackupError: Bool = false
    @State private var showRestoreConfirm: Bool = false
    @State private var showRestoreSuccess: Bool = false
    @State private var showRestoreError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedBackupURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Text("Backup & Restore")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "ffa751"), Color(hex: "ffe259")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Protect your reading data")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal, 32)

                VStack(spacing: 24) {
                    BackupCard(
                        title: "Create Backup",
                        description: "Export your entire library, reading progress, and statistics to a ZIP file",
                        icon: "arrow.up.circle.fill",
                        gradient: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                        action: createBackup
                    )
                    
                    BackupCard(
                        title: "Restore from Backup",
                        description: "Replace all current data with a previously saved backup",
                        icon: "arrow.down.circle.fill",
                        gradient: [Color(hex: "eb3349"), Color(hex: "f45c43")],
                        action: selectBackupFile
                    )
                }
                .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("Important Information")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(
                            icon: "checkmark.circle.fill",
                            text: "Backups include all books, reading progress, reviews, and ratings",
                            color: .green
                        )
                        
                        InfoRow(
                            icon: "exclamationmark.circle.fill",
                            text: "Restoring a backup will replace ALL current data",
                            color: .orange
                        )
                        
                        InfoRow(
                            icon: "clock.fill",
                            text: "Create regular backups to avoid losing your reading history",
                            color: .blue
                        )
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 32)
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .alert("Backup Created", isPresented: $showBackupSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your backup has been saved successfully.")
        }
        .alert("Backup Failed", isPresented: $showBackupError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Restore from Backup?", isPresented: $showRestoreConfirm) {
            Button("Cancel", role: .cancel) {
                selectedBackupURL = nil
            }
            Button("Restore", role: .destructive) {
                restoreBackup()
            }
        } message: {
            Text("This will replace ALL current data with the backup. This action cannot be undone.")
        }
        .alert("Restore Complete", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your data has been restored successfully. The app will now restart.")
        }
        .alert("Restore Failed", isPresented: $showRestoreError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "zip")!]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        panel.nameFieldStringValue = "booklet_backup_\(dateString).zip"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try dbManager.createBackup(to: url)
                    showBackupSuccess = true
                } catch {
                    errorMessage = error.localizedDescription
                    showBackupError = true
                }
            }
        }
    }
    
    private func selectBackupFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "zip")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { response in
            if response == .OK, let url = panel.urls.first {
                selectedBackupURL = url
                showRestoreConfirm = true
            }
        }
    }
    
    private func restoreBackup() {
        guard let url = selectedBackupURL else { return }
        
        do {
            try dbManager.restoreBackup(from: url)
            showRestoreSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            errorMessage = error.localizedDescription
            showRestoreError = true
        }
        
        selectedBackupURL = nil
    }
}

struct BackupCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 16 : 10, x: 0, y: isHovered ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: isHovered ? gradient.map { $0.opacity(0.3) } : [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
